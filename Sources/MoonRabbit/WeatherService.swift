import Foundation
import Combine

struct WeatherPlace: Codable, Identifiable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let admin1: String?
    let country: String?
    var label: String { [name, admin1, country].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ") }

}
struct CurrentWeather: Decodable {
    let time: String
    let temperature_2m: Double
    let apparent_temperature: Double
    let weather_code: Int
    let wind_speed_10m: Double
    var descriptionKey: String {
        switch weather_code {
        case 0: return "맑음"
        case 1, 2: return "대체로 맑음"
        case 3: return "흐림"
        case 45, 48: return "안개"
        case 51...57: return "이슬비"
        case 61...67, 80...82: return "비"
        case 71...77, 85, 86: return "눈"
        case 95...99: return "뇌우"
        default: return "날씨 정보"
        }
    }
}
struct WeatherService {
    static func searchURL(query: String, language: AppLanguage) -> URL {
        var url = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        url.queryItems = [URLQueryItem(name: "name", value: query), URLQueryItem(name: "count", value: "5"), URLQueryItem(name: "language", value: language.rawValue), URLQueryItem(name: "format", value: "json")]
        return url.url!
    }
    static func forecastURL(place: WeatherPlace) -> URL {
        var url = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        url.queryItems = [URLQueryItem(name: "latitude", value: String(place.latitude)), URLQueryItem(name: "longitude", value: String(place.longitude)), URLQueryItem(name: "current", value: "temperature_2m,apparent_temperature,weather_code,wind_speed_10m"), URLQueryItem(name: "timezone", value: "auto")]
        return url.url!
    }
    static func load<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.setValue("MoonRabbitDesktop/1.4 (user-initiated weather search)", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw URLError(.badServerResponse) }
        return try JSONDecoder().decode(type, from: data)
    }
    static func searchCities(query: String, language: AppLanguage) async throws -> [WeatherPlace] {
        struct Response: Decodable { let results: [WeatherPlace]? }
        return try await load(Response.self, from: searchURL(query: query, language: language)).results ?? []
    }
    static func neighborhoodURL(query: String, language: AppLanguage) -> URL {
        var url = URLComponents(string: "https://photon.komoot.io/api/")!
        url.queryItems = [URLQueryItem(name: "q", value: query), URLQueryItem(name: "limit", value: "8"),
                         URLQueryItem(name: "osm_tag", value: "place"), URLQueryItem(name: "osm_tag", value: "boundary")]
        if language == .en { url.queryItems?.append(URLQueryItem(name: "lang", value: "en")) }
        return url.url!
    }
    struct NeighborhoodResponse: Decodable {
        struct Feature: Decodable {
            struct Properties: Decodable { let name: String?; let city: String?; let state: String?; let country: String? }
            struct Geometry: Decodable { let coordinates: [Double] }
            let properties: Properties
            let geometry: Geometry
        }
        let features: [Feature]
        var places: [WeatherPlace] {
            var seen = Set<String>()
            return features.enumerated().compactMap { index, feature in
                let p = feature.properties
                guard let name = p.name, feature.geometry.coordinates.count >= 2 else { return nil }
                let area = [p.city, p.state].compactMap { $0 }.filter { $0 != name }.joined(separator: ", ")
                let place = WeatherPlace(id: -(index + 1), name: name, latitude: feature.geometry.coordinates[1],
                                         longitude: feature.geometry.coordinates[0], admin1: area, country: p.country)
                guard seen.insert(place.label).inserted else { return nil }
                return place
            }
        }
    }
    @MainActor private static var searchCache: [String: [WeatherPlace]] = [:]
    @MainActor static func search(query: String, language: AppLanguage) async throws -> [WeatherPlace] {
        let key = language.rawValue + ":" + query
        if let cached = searchCache[key] { return cached }
        let response = try await load(NeighborhoodResponse.self, from: neighborhoodURL(query: query, language: language))
        try Task.checkCancellation()
        let places = response.places
        let result = places.isEmpty ? try await searchCities(query: query, language: language) : places
        searchCache[key] = result
        return result
    }
    static func current(place: WeatherPlace) async throws -> CurrentWeather {
        struct Response: Decodable { let current: CurrentWeather }
        return try await load(Response.self, from: forecastURL(place: place)).current
    }
}

@MainActor final class WeatherModel: ObservableObject {
    @Published var query = ""
    @Published var places: [WeatherPlace] = []
    @Published var selected: WeatherPlace?
    @Published var current: CurrentWeather?
    @Published var loading = false
    @Published var status = "한글·영문으로 도시나 동네를 검색하세요."
    private var task: Task<Void, Never>?
    init() {
        if let data = UserDefaults.standard.data(forKey: "weatherPlace"), let place = try? JSONDecoder().decode(WeatherPlace.self, from: data) {
            selected = place; query = place.name
        }
    }
    func search(language: AppLanguage) {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else { status = "지역 이름을 두 글자 이상 입력하세요."; return }
        task?.cancel(); places = []; current = nil; loading = true; status = "검색 중…"
        task = Task {
            do {
                let places = try await WeatherService.search(query: query, language: language)
                guard !Task.isCancelled else { return }
                self.places = places; self.loading = false
                self.status = places.isEmpty ? "지역을 찾지 못했어요. 시·구와 동네 이름을 함께 입력해 주세요." : "주소를 확인하고 지역을 선택하세요."
            } catch {
                guard !Task.isCancelled else { return }
                self.loading = false; self.status = "연결하지 못했어요. 인터넷을 확인하고 다시 시도해 주세요."
            }
        }
    }
    func fetch(_ place: WeatherPlace, failed: ((String) -> Void)? = nil, report: @escaping (WeatherPlace, CurrentWeather) -> Void) {
        task?.cancel(); loading = true; current = nil; selected = place; places = []; status = "날씨 확인 중…"
        if let data = try? JSONEncoder().encode(place) { UserDefaults.standard.set(data, forKey: "weatherPlace") }
        task = Task {
            do {
                let weather = try await WeatherService.current(place: place)
                guard !Task.isCancelled else { return }
                self.current = weather; self.loading = false; self.status = ""
                report(place, weather)
            } catch {
                guard !Task.isCancelled else { return }
                self.loading = false; self.status = "연결하지 못했어요. 인터넷을 확인하고 다시 시도해 주세요."
                failed?(self.status)
            }
        }
    }
}
