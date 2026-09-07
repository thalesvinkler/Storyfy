import Foundation

protocol PersistenceServing {
    func loadPreferences() -> StoryfyPreferences?
    func savePreferences(_ preferences: StoryfyPreferences)
    func loadArchives() -> [StoryArchive]
    func saveArchives(_ archives: [StoryArchive])
}

struct UserDefaultsPersistenceStore: PersistenceServing {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadPreferences() -> StoryfyPreferences? {
        guard let data = defaults.data(forKey: Keys.preferences) else { return nil }
        return try? decoder.decode(StoryfyPreferences.self, from: data)
    }

    func savePreferences(_ preferences: StoryfyPreferences) {
        guard let data = try? encoder.encode(preferences) else { return }
        defaults.set(data, forKey: Keys.preferences)
    }

    func loadArchives() -> [StoryArchive] {
        guard let data = defaults.data(forKey: Keys.archives) else { return [] }
        return (try? decoder.decode([StoryArchive].self, from: data)) ?? []
    }

    func saveArchives(_ archives: [StoryArchive]) {
        guard let data = try? encoder.encode(archives) else { return }
        defaults.set(data, forKey: Keys.archives)
    }

    private enum Keys {
        static let preferences = "storyfy.preferences.v1"
        static let archives = "storyfy.archives.v1"
    }
}
