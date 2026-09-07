import Foundation

protocol CurationServing { func select(from photos: [PhotoCandidate], limit: Int) -> [PhotoCandidate] }

struct LocalCurationService: CurationServing {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func select(from photos: [PhotoCandidate], limit: Int = 15) -> [PhotoCandidate] {
        guard !photos.isEmpty else { return [] }
        let deduplicated = bestFromBursts(photos.sorted { $0.createdAt < $1.createdAt })
        guard deduplicated.count > limit else { return deduplicated }

        let ranked = deduplicated.sorted(by: qualityOrder)
        var selected: [PhotoCandidate] = []

        // First pass: guarantee temporal coverage across the month.
        let weekGroups = Dictionary(grouping: ranked) { calendar.component(.weekOfMonth, from: $0.createdAt) }
        for week in weekGroups.keys.sorted() {
            if let best = weekGroups[week]?.first { selected.append(best) }
        }

        // Second pass: maximize quality while avoiding one day or theme dominating the story.
        for candidate in ranked where selected.count < limit && !selected.contains(candidate) {
            let sameDayCount = selected.filter { calendar.isDate($0.createdAt, inSameDayAs: candidate.createdAt) }.count
            let sameEventCount = selected.filter { $0.event == candidate.event }.count
            let sameLocationCount = selected.filter { $0.locationBucket != nil && $0.locationBucket == candidate.locationBucket }.count
            if sameDayCount < 2 && sameEventCount < max(3, limit / 3) && sameLocationCount < max(4, limit / 2) { selected.append(candidate) }
        }

        // Fill remaining slots when the month has little variety.
        for candidate in ranked where selected.count < limit && !selected.contains(candidate) {
            selected.append(candidate)
        }
        return selected.prefix(limit).sorted { $0.createdAt < $1.createdAt }
    }

    private func bestFromBursts(_ photos: [PhotoCandidate]) -> [PhotoCandidate] {
        var groups: [[PhotoCandidate]] = []
        for photo in photos {
            if let last = groups.last?.last, photo.createdAt.timeIntervalSince(last.createdAt) <= 8 {
                groups[groups.count - 1].append(photo)
            } else {
                groups.append([photo])
            }
        }
        return groups.flatMap { group in
            let allowance = group.count >= 8 ? 2 : 1
            return group.sorted(by: qualityOrder).prefix(allowance)
        }
    }

    private func qualityOrder(_ left: PhotoCandidate, _ right: PhotoCandidate) -> Bool {
        left.score == right.score ? left.createdAt < right.createdAt : left.score > right.score
    }
}
