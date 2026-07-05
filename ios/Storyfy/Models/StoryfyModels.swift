import Foundation
import Photos

enum AppScreen: Hashable {
    case welcome, privacy, home, processing, review, caption, finish
}

struct PhotoCandidate: Identifiable, Hashable {
    let id: String
    let asset: PHAsset
    let createdAt: Date
    let score: Double

    static func == (lhs: PhotoCandidate, rhs: PhotoCandidate) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct MonthInterval: Equatable {
    let start: Date
    let end: Date

    static func previous(to date: Date = .now, calendar: Calendar = .current) -> MonthInterval {
        let currentStart = calendar.dateInterval(of: .month, for: date)!.start
        let previousStart = calendar.date(byAdding: .month, value: -1, to: currentStart)!
        return MonthInterval(start: previousStart, end: currentStart)
    }

    var displayName: String {
        start.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "pt_BR")))
    }
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
