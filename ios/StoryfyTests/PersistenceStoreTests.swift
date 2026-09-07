import XCTest
@testable import Storyfy

final class PersistenceStoreTests: XCTestCase {
    func testPersistsPreferencesAndArchives() {
        let suiteName = "PersistenceStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsPersistenceStore(defaults: defaults)
        let preferences = StoryfyPreferences(selectedMonthStart: Date(timeIntervalSince1970: 100), writingProfile: "@storyfy", writingExamples: "Dias bons.", instagramConnectionID: "connection-1")
        let archive = StoryArchive(id: UUID(), monthStart: Date(timeIntervalSince1970: 100), createdAt: Date(timeIntervalSince1970: 200), photoCount: 10, caption: "Legenda", assetIdentifiers: ["photo-1"])

        store.savePreferences(preferences)
        store.saveArchives([archive])

        XCTAssertEqual(store.loadPreferences(), preferences)
        XCTAssertEqual(store.loadArchives(), [archive])
    }
}
