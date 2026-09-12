import Foundation
import Security
import SwiftUI

/// Optional personal-key access. No app-owned credential, automatic retries, or tool execution.
enum PersonalAPI {
    static let providers = ["OpenAI", "Gemini", "Claude"]
    static let portals = ["OpenAI": "https://platform.openai.com/api-keys", "Gemini": "https://aistudio.google.com/apikey", "Claude": "https://platform.claude.com/settings/keys"]
    static func query(_ provider: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "moonrabbit.personal-api", kSecAttrAccount as String: provider]
    }
    static func key(_ provider: String) throws -> String {
        guard providers.contains(provider) else { throw Failure.invalid }
        var q = query(provider); q[kSecReturnData as String] = true; q[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &result) == errSecSuccess, let data = result as? Data, let value = String(data: data, encoding: .utf8) else { throw Failure.missingKey }
        return value
    }
    static func save(_ value: String, provider: String) throws {
        guard providers.contains(provider), (10...512).contains(value.count), !value.contains(where: { $0.isWhitespace }) else { throw Failure.invalid }
        let q = query(provider), data = Data(value.utf8)
        let result = SecItemUpdate(q as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if result == errSecItemNotFound {
            var insert = q; insert[kSecValueData as String] = data; insert[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            guard SecItemAdd(insert as CFDictionary, nil) == errSecSuccess else { throw Failure.storage }
        } else if result != errSecSuccess { throw Failure.storage }
    }
    static func remove(_ provider: String) throws {
        guard providers.contains(provider) else { throw Failure.invalid }
        let result = SecItemDelete(query(provider) as CFDictionary)
        guard result == errSecSuccess || result == errSecItemNotFound else { throw Failure.storage }
    }
    enum Failure: Error { case invalid, missingKey, storage, http(Int), empty }
    static func request(provider: String, model: String, prompt: String, key: String) throws -> URLRequest {
        guard providers.contains(provider), !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, prompt.count <= 20000,
              model.range(of: "^[a-zA-Z0-9._:-]{1,100}$", options: .regularExpression) != nil else { throw Failure.invalid }
        let url: String
        let body: [String: Any]
        switch provider {
        case "OpenAI": url = "https://api.openai.com/v1/responses"; body = ["model": model, "input": prompt, "store": false, "max_output_tokens": 2048]
        case "Gemini": url = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent"; body = ["contents": [["parts": [["text": prompt]]]], "generationConfig": ["maxOutputTokens": 2048]]
        default: url = "https://api.anthropic.com/v1/messages"; body = ["model": model, "max_tokens": 2048, "messages": [["role": "user", "content": prompt]]]
        }
        var request = URLRequest(url: URL(string: url)!, timeoutInterval: 60)
        request.httpMethod = "POST"; request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if provider == "OpenAI" { request.setValue("Bearer " + key, forHTTPHeaderField: "Authorization") }
        else if provider == "Gemini" { request.setValue(key, forHTTPHeaderField: "x-goog-api-key") }
        else { request.setValue(key, forHTTPHeaderField: "x-api-key"); request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version") }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }
    static func response(_ data: Data, provider: String) throws -> String {
        guard data.count < 2_000_000, let value = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw Failure.empty }
        var chunks: [[String: Any]] = []
        if provider == "OpenAI" {
            let output = value["output"] as? [[String: Any]] ?? []
            for item in output { chunks.append(contentsOf: item["content"] as? [[String: Any]] ?? []) }
        } else if provider == "Gemini" {
            let candidates = value["candidates"] as? [[String: Any]] ?? []
            if let first = candidates.first {
                let content = first["content"] as? [String: Any] ?? [:]
                chunks = content["parts"] as? [[String: Any]] ?? []
            }
        } else { chunks = value["content"] as? [[String: Any]] ?? [] }
        let text = chunks.compactMap { $0["text"] as? String }.joined(separator: "\n")
        guard !text.isEmpty else { throw Failure.empty }; return text
    }
    final class NoRedirect: NSObject, URLSessionTaskDelegate {
        func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) { completionHandler(nil) }
    }
    static func send(provider: String, model: String, prompt: String) async throws -> String {
        let request = try request(provider: provider, model: model, prompt: prompt, key: key(provider))
        let session = URLSession(configuration: .ephemeral, delegate: NoRedirect(), delegateQueue: nil)
        defer { session.invalidateAndCancel() }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw Failure.empty }
        guard (200..<300).contains(http.statusCode) else { throw Failure.http(http.statusCode) }
        return try self.response(data, provider: provider)
    }
}

struct PersonalAPIView: View {
    let english: Bool
    let initialPrompt: String
    @Environment(\.dismiss) private var dismiss
    @State private var provider = "OpenAI"
    @State private var model = ""
    @State private var secret = ""
    @State private var prompt = ""
    @State private var answer = ""
    @State private var status = ""
    @State private var consent = false
    @State private var busy = false
    @State private var task: Task<Void, Never>?
    private func t(_ ko: String, _ en: String) -> String { english ? en : ko }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack { Text(t("내 API 연결 · 선택 기능", "Personal API · optional")).font(.title2); Spacer(); Button(t("닫기", "Close")) { task?.cancel(); dismiss() } }
                Text(t("플래너는 무료입니다. API 호출은 제공자 계정에 별도 요금이 발생할 수 있으며 ChatGPT 구독과는 별개입니다. 키는 이 기기의 키체인에만 저장합니다.", "The planner is free. API requests may bill your provider account separately from a ChatGPT subscription. Keys stay in this device’s Keychain.")).font(.subheadline)
                credentials.disabled(busy)
                requestForm.disabled(busy)
                if busy { ProgressView() }
                Text(status).font(.caption)
                if !answer.isEmpty { Text(answer).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading) }
            }.padding(24)
        }.frame(idealWidth: 620, minHeight: 540)
            .onAppear { prompt = initialPrompt }
            .onChange(of: provider) { _ in secret = ""; model = ""; consent = false; status = "" }
            .onDisappear { secret = ""; task?.cancel() }
    }
    private var credentials: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker(t("제공자", "Provider"), selection: $provider) { ForEach(PersonalAPI.providers, id: \.self) { Text($0).tag($0) } }
            Link(t("내 계정에서 API 키 관리 ↗", "Manage API keys in my account ↗"), destination: URL(string: PersonalAPI.portals[provider]!)!)
            SecureField(t("내 API 키", "My API key"), text: $secret).textFieldStyle(.roundedBorder)
            HStack {
                Button(t("키 안전하게 저장", "Save key securely"), action: saveKey).disabled(secret.isEmpty)
                Button(role: .destructive, action: deleteKey) { Text(t("저장한 키 삭제", "Delete saved key")) }
            }
            TextField(t("사용할 모델 ID (제공자 콘솔에서 확인)", "Model ID (see provider console)"), text: $model).textFieldStyle(.roundedBorder)
        }
    }
    private var requestForm: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(t("보낼 지시문", "Instructions to send")).font(.headline)
            TextEditor(text: $prompt).frame(minHeight: 150).border(Color.secondary.opacity(0.2))
            Toggle(t("위 지시문 전송과 내 API 사용 요금을 확인했습니다", "I accept sending these instructions and any API charges"), isOn: $consent)
            Button(t("내 API로 1회 전송", "Send once with my API"), action: send)
                .buttonStyle(.borderedProminent).disabled(!consent || model.isEmpty || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
    private func saveKey() {
        do { try PersonalAPI.save(secret.trimmingCharacters(in: .whitespacesAndNewlines), provider: provider); secret = ""; status = t("키 저장 완료 · 아직 요청하지 않았어요", "Key saved · no request sent") }
        catch { status = t("키를 저장하지 못했어요. 입력과 키체인 접근 권한을 확인하세요.", "Could not save. Check the key and Keychain access.") }
    }
    private func deleteKey() {
        do { try PersonalAPI.remove(provider); secret = ""; status = t("키 삭제 완료", "Key deleted") }
        catch { status = t("키를 삭제하지 못했어요", "Could not delete key") }
    }
    private func send() {
        guard consent && !busy else { return }
        busy = true; answer = ""; consent = false
        task = Task { @MainActor in
            defer { busy = false }
            do { answer = try await PersonalAPI.send(provider: provider, model: model, prompt: prompt); status = t("응답을 받았어요", "Response received") }
            catch PersonalAPI.Failure.http(let code) { status = t("요청 실패 (HTTP \(code)). 키·모델·잔액·한도를 제공자 콘솔에서 확인하세요.", "Request failed (HTTP \(code)). Check key, model, billing and limits in the provider console.") }
            catch { status = t("요청하지 못했어요. 키 저장 여부·모델 ID·네트워크를 확인하세요. 자동 재시도는 하지 않습니다.", "Request failed. Check saved key, model ID and connection. No automatic retry.") }
        }
    }
}
