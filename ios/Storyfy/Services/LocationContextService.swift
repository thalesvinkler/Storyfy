import CoreLocation
import Foundation

actor LocationContextService {
    private let geocoder = CLGeocoder()
    private var cache: [String: String] = [:]

    func names(for photos: [PhotoCandidate]) async -> [String: String] {
        var result: [String: String] = [:]
        for photo in photos {
            guard let latitude = photo.latitude, let longitude = photo.longitude, let bucket = photo.locationBucket else { continue }
            if let cached = cache[bucket] {
                result[photo.id] = cached
                continue
            }
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(CLLocation(latitude: latitude, longitude: longitude), preferredLocale: Locale(identifier: "pt_BR"))
                if let placemark = placemarks.first {
                    let name = placemark.locality ?? placemark.subAdministrativeArea ?? placemark.administrativeArea ?? placemark.country
                    if let name { cache[bucket] = name; result[photo.id] = name }
                }
            } catch {
                continue
            }
        }
        return result
    }
}
