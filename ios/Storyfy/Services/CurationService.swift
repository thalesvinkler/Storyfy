import Foundation

protocol CurationServing { func select(from photos: [PhotoCandidate], limit: Int) -> [PhotoCandidate] }

struct LocalCurationService: CurationServing {
    func select(from photos: [PhotoCandidate], limit: Int = 15) -> [PhotoCandidate] {
        guard photos.count > limit else { return photos.sorted { $0.createdAt < $1.createdAt } }
        let ranked = photos.sorted {
            if $0.score == $1.score { return $0.createdAt < $1.createdAt }
            return $0.score > $1.score
        }
        var chosen: [PhotoCandidate] = []
        let calendar = Calendar.current
        let groups = Dictionary(grouping: ranked) { calendar.component(.weekOfMonth, from: $0.createdAt) }
        var indexes = Dictionary(uniqueKeysWithValues: groups.keys.map { ($0, 0) })
        let weeks = groups.keys.sorted()
        while chosen.count < limit {
            var added = false
            for week in weeks where chosen.count < limit {
                guard let items = groups[week], let index = indexes[week], index < items.count else { continue }
                chosen.append(items[index]); indexes[week] = index + 1; added = true
            }
            if !added { break }
        }
        return chosen.sorted { $0.createdAt < $1.createdAt }
    }
}
