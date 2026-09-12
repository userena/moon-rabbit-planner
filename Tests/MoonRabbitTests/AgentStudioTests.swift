import XCTest
@testable import MoonRabbit
final class AgentStudioTests: XCTestCase {
    func testPromptAndPersistence() throws {
        var doc = StudioDocument.initial(english: false)
        doc.project = "프로젝트"
        doc.context = "요구사항"
        doc.blueprint = "화면 → 저장"
        doc.agents[0].task = "인터뷰 정리"
        doc.agents[0].output = "보고서"
        let decoded = try JSONDecoder().decode(StudioDocument.self, from: JSONEncoder().encode(doc))
        XCTAssertEqual(decoded, doc)
        for english in [false, true] {
            let prompt = decoded.prompt(for: decoded.agents[0], english: english)
            for expected in ["프로젝트", "요구사항", "화면 → 저장", "인터뷰 정리", "보고서", "기획 → 설계 → 디자인 → 개발 → 검토 → 배포 → 유지보수"] { XCTAssertTrue(prompt.contains(expected)) }
        }
        doc.agents = []
        XCTAssertTrue(try JSONDecoder().decode(StudioDocument.self, from: JSONEncoder().encode(doc)).agents.isEmpty)
    }
}
