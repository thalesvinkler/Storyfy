import Foundation
import Photos

enum AppScreen: Hashable {
    case privacy, home, processing, review, caption, finish, writingStyle, paywall
}

enum BillingPlan: String, CaseIterable, Hashable {
    case free, plus, creator

    var title: String {
        switch self {
        case .free: "Free"
        case .plus: "Plus"
        case .creator: "Creator"
        }
    }

    var captionLimit: Int {
        switch self {
        case .free: 2
        case .plus: 20
        case .creator: 150
        }
    }
}

struct PhotoCandidate: Identifiable, Hashable {
    let id: String
    let asset: PHAsset?
    let createdAt: Date
    let score: Double
    let event: String
    let symbol: String
    let colorIndex: Int
    let latitude: Double?
    let longitude: Double?
    let locationName: String?
    let calendarEvent: String?

    init(id: String, asset: PHAsset?, createdAt: Date, score: Double, event: String, symbol: String, colorIndex: Int, latitude: Double? = nil, longitude: Double? = nil, locationName: String? = nil, calendarEvent: String? = nil) {
        self.id = id
        self.asset = asset
        self.createdAt = createdAt
        self.score = score
        self.event = event
        self.symbol = symbol
        self.colorIndex = colorIndex
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
        self.calendarEvent = calendarEvent
    }

    var locationBucket: String? {
        guard let latitude, let longitude else { return nil }
        return "\((latitude * 10).rounded() / 10),\((longitude * 10).rounded() / 10)"
    }

    func contextualized(locationName: String?, calendarEvent: String?) -> PhotoCandidate {
        let contextEvent = calendarEvent ?? locationName ?? event
        return PhotoCandidate(id: id, asset: asset, createdAt: createdAt, score: score, event: contextEvent, symbol: symbol, colorIndex: colorIndex, latitude: latitude, longitude: longitude, locationName: locationName, calendarEvent: calendarEvent)
    }

    static func == (lhs: PhotoCandidate, rhs: PhotoCandidate) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct StoryEvent: Identifiable, Hashable {
    let name: String
    let symbol: String
    let sourceCount: Int
    let selectedCount: Int

    var id: String { name }

    var emoji: String {
        let normalized = name.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        if normalized.contains("viagem") || normalized.contains("paisagem") { return "✈️" }
        if normalized.contains("famil") || normalized.contains("casa") { return "👨‍👩‍👧" }
        if normalized.contains("amig") || normalized.contains("festa") { return "🥂" }
        if normalized.contains("treino") || normalized.contains("rotina") { return "🏃" }
        if normalized.contains("trabalho") { return "💻" }
        return "✨"
    }
}

struct MonthInterval: Equatable {
    let start: Date
    let end: Date

    static func previous(to date: Date = .now, calendar: Calendar = .current) -> MonthInterval {
        let currentStart = calendar.dateInterval(of: .month, for: date)!.start
        let previousStart = calendar.date(byAdding: .month, value: -1, to: currentStart)!
        return MonthInterval(start: previousStart, end: currentStart)
    }

    static func containing(_ date: Date, calendar: Calendar = .current) -> MonthInterval {
        let interval = calendar.dateInterval(of: .month, for: date)!
        return MonthInterval(start: interval.start, end: interval.end)
    }

    var displayName: String {
        start.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "pt_BR")))
    }
}

struct StoryArchive: Codable, Identifiable, Equatable {
    let id: UUID
    let monthStart: Date
    let createdAt: Date
    let photoCount: Int
    let caption: String
    let assetIdentifiers: [String]

    var monthName: String {
        monthStart.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "pt_BR"))).capitalized
    }
}

struct StoryfyPreferences: Codable, Equatable {
    var selectedMonthStart: Date
    var writingProfile: String
    var writingExamples: String
    var instagramConnectionID: String?
}

enum PhotoAccessState: Equatable {
    case notDetermined, authorized, limited, denied
}

enum StoryfyError: LocalizedError {
    case accessDenied, noPhotos, albumCreationFailed

    var errorDescription: String? {
        switch self {
        case .accessDenied: "O Storyfy precisa de acesso às fotos para criar a retrospectiva."
        case .noPhotos: "Não encontramos fotos elegíveis no mês anterior."
        case .albumCreationFailed: "Não foi possível criar o álbum no Apple Photos."
        }
    }
}
