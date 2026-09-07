import Foundation
import Photos
import Observation
import UIKit
import SwiftUI

@MainActor
@Observable
final class AppModel {
    var screen: AppScreen
    var access: PhotoAccessState = .notDetermined
    var photos: [PhotoCandidate] = []
    var availablePhotos: [PhotoCandidate] = []
    var caption = ""
    var progress = 0.0
    var statusMessage = "Preparando sua história…"
    var errorMessage: String?
    var albumCreated = false
    var sourcePhotoCount = 0
    var storyEvents: [StoryEvent] = []
    var month = MonthInterval.previous()
    var writingProfile = ""
    var writingExamples = ""
    var usesWritingStyle = false
    var instagramConnectionID: String?
    var isConnectingInstagram = false
    var archives: [StoryArchive] = []
    var isGeneratingCaption = false
    var captionUsedFallback = false
    var captionFallbackReason: CaptionFallbackReason?
    var captionQuota: CaptionQuota?
    var billingPlan = BillingPlan.free
    var billingProducts: [BillingProduct] = []
    var isLoadingBilling = false
    var calendarConnected = false
    var isConnectingCalendar = false
    var calendarStatusMessage = "Não conectado"
    var locationNamesEnabled = false
    var lastRemovedPhoto: PhotoCandidate?
    var lastRemovedIndex: Int?

    private let library: PhotoLibraryServing
    private let curator: CurationServing
    private let captions: CaptionServing
    private let persistence: PersistenceServing
    private let instagram: InstagramServing
    private let calendarService: CalendarServing
    private let locationService: LocationContextService
    private let billing: BillingServing
    private let entitlementSync: EntitlementSyncServing
    private var captionVariant = 0
    private var buildIdentifier = UUID()

    init(library: PhotoLibraryServing = PhotoLibraryService(), curator: CurationServing = LocalCurationService(), captions: CaptionServing = SmartCaptionService(), persistence: PersistenceServing = UserDefaultsPersistenceStore(), instagram: InstagramServing? = nil, calendarService: CalendarServing = CalendarService(), locationService: LocationContextService = LocationContextService(), billing: BillingServing = StoreKitBillingService(), entitlementSync: EntitlementSyncServing = SupabaseEntitlementSyncService()) {
        self.library = library; self.curator = curator; self.captions = captions; self.persistence = persistence; self.instagram = instagram ?? InstagramService(); self.calendarService = calendarService; self.locationService = locationService; self.billing = billing; self.entitlementSync = entitlementSync
        screen = .privacy
        if let preferences = persistence.loadPreferences() {
            month = .containing(preferences.selectedMonthStart)
            writingProfile = preferences.writingProfile
            writingExamples = preferences.writingExamples
            instagramConnectionID = preferences.instagramConnectionID
            usesWritingStyle = !writingProfile.isEmpty || !writingExamples.isEmpty
        }
        archives = persistence.loadArchives().sorted { $0.createdAt > $1.createdAt }
        calendarConnected = false
        let currentAccess = library.accessState()
        access = currentAccess
        screen = currentAccess == .authorized || currentAccess == .limited ? .home : .privacy
    }

    func requestPhotoAccess() async {
        access = await library.requestAccess()
        if access == .authorized || access == .limited { screen = .home }
        else { errorMessage = StoryfyError.accessDenied.localizedDescription }
    }

    func buildStory() async {
        let identifier = UUID()
        buildIdentifier = identifier
        screen = .processing; errorMessage = nil; progress = 0.22
        do {
            statusMessage = "Buscando as fotos de \(month.displayName)…"
            let candidates = try await library.candidates(in: month)
            guard !candidates.isEmpty else { throw StoryfyError.noPhotos }
            availablePhotos = candidates
            sourcePhotoCount = candidates.count
            progress = 0.38; statusMessage = "Removendo repetidas e screenshots…"
            try? await Task.sleep(for: .milliseconds(550))
            guard buildIdentifier == identifier else { return }
            progress = 0.68; statusMessage = "Agrupando viagens, encontros e rotina…"
            try? await Task.sleep(for: .milliseconds(550))
            guard buildIdentifier == identifier else { return }
            progress = 0.86; statusMessage = "Criando uma sequencia com ritmo…"
            photos = curator.select(from: candidates, limit: 15)
            progress = 0.92; statusMessage = "Organizando os momentos finais…"
            let calendarMoments = calendarConnected ? await calendarService.moments(in: month) : []
            let locationNames = locationNamesEnabled ? await locationService.names(for: photos) : [:]
            photos = Self.addContext(to: photos, calendarMoments: calendarMoments, locationNames: locationNames)
            storyEvents = Self.makeEvents(from: photos, sourceCount: sourcePhotoCount)
            progress = 1; statusMessage = "Sua retrospectiva está pronta."
            try? await Task.sleep(for: .milliseconds(450))
            guard buildIdentifier == identifier else { return }
            screen = .review
        } catch { errorMessage = error.localizedDescription; screen = .home }
    }

    func remove(_ photo: PhotoCandidate) {
        guard let index = photos.firstIndex(of: photo) else { return }
        lastRemovedPhoto = photo
        lastRemovedIndex = index
        photos.remove(at: index)
        refreshEvents()
    }

    func undoRemove() {
        guard let photo = lastRemovedPhoto else { return }
        let index = min(lastRemovedIndex ?? photos.count, photos.count)
        photos.insert(photo, at: index)
        lastRemovedPhoto = nil
        lastRemovedIndex = nil
        refreshEvents()
    }

    func add(_ photo: PhotoCandidate) {
        guard photos.count < 20, !photos.contains(photo) else { return }
        photos.append(photo)
        refreshEvents()
    }

    func makeCover(_ photo: PhotoCandidate) {
        guard let index = photos.firstIndex(of: photo), index != 0 else { return }
        photos.move(fromOffsets: IndexSet(integer: index), toOffset: 0)
    }

    var suggestedPhotos: [PhotoCandidate] {
        availablePhotos.filter { !photos.contains($0) }.sorted { $0.score > $1.score }
    }
    func move(from source: IndexSet, to destination: Int) { photos.move(fromOffsets: source, toOffset: destination) }

    func prepareCaption() async {
        screen = .caption
        await generateCaption()
    }

    func regenerateCaption() async {
        captionVariant += 1
        await generateCaption()
    }

    func selectMonth(_ date: Date) {
        month = .containing(date)
        photos = []
        storyEvents = []
        sourcePhotoCount = 0
        savePreferences()
    }

    func saveWritingStyle(profile: String, examples: String) {
        writingProfile = profile.trimmingCharacters(in: .whitespacesAndNewlines)
        writingExamples = examples.trimmingCharacters(in: .whitespacesAndNewlines)
        usesWritingStyle = !writingProfile.isEmpty || !writingExamples.isEmpty
        savePreferences()
        screen = .home
    }

    func connectInstagram() async {
        isConnectingInstagram = true
        defer { isConnectingInstagram = false }
        do {
            let result = try await instagram.connect()
            instagramConnectionID = result.connectionID
            writingProfile = "@\(result.profile.username)"
            writingExamples = result.profile.captions.prefix(30).joined(separator: "\n\n")
            usesWritingStyle = !writingExamples.isEmpty
            savePreferences()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func disconnectInstagram() async {
        let connectionID = instagramConnectionID
        instagramConnectionID = nil
        writingProfile = ""
        writingExamples = ""
        usesWritingStyle = false
        savePreferences()
        if let connectionID {
            do {
                try await instagram.disconnect(connectionID: connectionID)
            } catch {
                errorMessage = "Removemos o Instagram deste aparelho. Se quiser apagar no servidor agora, tente desconectar novamente quando estiver online."
            }
        }
    }

    func connectCalendar() async {
        isConnectingCalendar = true
        calendarConnected = await calendarService.requestAccess()
        isConnectingCalendar = false
        calendarStatusMessage = calendarConnected
            ? "Acesso permitido. Eventos serão usados para identificar momentos."
            : "Acesso indisponível. Verifique Calendário em Ajustes do iPhone."
    }

    func refreshBilling() async {
        isLoadingBilling = true
        async let products = billing.products()
        async let plan = billing.activePlan()
        billingProducts = await products
        billingPlan = await plan
        isLoadingBilling = false
    }

    func purchase(_ product: BillingProduct) async {
        isLoadingBilling = true
        defer { isLoadingBilling = false }
        do {
            let result = try await billing.purchase(product)
            billingPlan = result.plan
            if result.productID != nil {
                billingPlan = try await entitlementSync.sync(result)
            }
            screen = .home
        } catch {
            errorMessage = "Não foi possível concluir a compra agora."
        }
    }

    func restorePurchases() async {
        isLoadingBilling = true
        let result = await billing.restore()
        billingPlan = result.plan
        if result.productID != nil, let syncedPlan = try? await entitlementSync.sync(result) {
            billingPlan = syncedPlan
        }
        isLoadingBilling = false
    }

    #if DEBUG
    func debugSetPlan(_ plan: BillingPlan) {
        billingPlan = plan
    }
    #endif

    func finish() { screen = .finish }

    func goBack() {
        switch screen {
        case .processing:
            buildIdentifier = UUID()
            progress = 0
            screen = .home
        case .review:
            screen = .home
        case .caption:
            screen = .review
        case .finish:
            screen = .caption
        case .writingStyle:
            screen = .home
        case .paywall:
            screen = .home
        case .privacy, .home:
            break
        }
    }

    var canGoBackInStory: Bool {
        [.review, .caption, .finish].contains(screen)
    }

    func createAlbum() async {
        do {
            try await library.createAlbum(named: "Storyfy — \(month.displayName.capitalized)", assets: photos.compactMap(\.asset))
            albumCreated = true
            archiveCurrentStory()
        } catch { errorMessage = error.localizedDescription }
    }

    func thumbnail(for photo: PhotoCandidate, size: CGSize) async -> UIImage? {
        guard let asset = photo.asset else { return nil }
        return await library.image(for: asset, size: size)
    }

    func sharePayload() async -> [Any] {
        var items: [Any] = []
        for photo in photos {
            if let asset = photo.asset, let image = await library.image(for: asset, size: CGSize(width: 2048, height: 2048)) { items.append(image) }
        }
        items.append(caption)
        return items
    }

    func restart() { photos = []; availablePhotos = []; caption = ""; captionUsedFallback = false; captionFallbackReason = nil; captionQuota = nil; progress = 0; albumCreated = false; errorMessage = nil; storyEvents = []; screen = .home }

    private func refreshEvents() {
        storyEvents = Self.makeEvents(from: photos, sourceCount: sourcePhotoCount)
    }

    private func savePreferences() {
        persistence.savePreferences(StoryfyPreferences(
            selectedMonthStart: month.start,
            writingProfile: writingProfile,
            writingExamples: writingExamples
            , instagramConnectionID: instagramConnectionID
        ))
    }

    private func generateCaption() async {
        isGeneratingCaption = true
        defer { isGeneratingCaption = false }
        let request = CaptionRequest(
            month: month.displayName.capitalized,
            photoCount: photos.count,
            events: storyEvents.map { "\($0.emoji) \($0.name)" },
            profile: writingProfile,
            writingExamples: writingExamples,
            variant: captionVariant
        )
        do {
            let result = try await captions.caption(for: request)
            caption = result.text
            captionUsedFallback = result.usedFallback
            captionFallbackReason = result.fallbackReason
            captionQuota = result.quota
        } catch {
            captionUsedFallback = false
            captionFallbackReason = nil
            errorMessage = "Não foi possível gerar a legenda agora."
        }
    }

    private func archiveCurrentStory() {
        let archive = StoryArchive(
            id: UUID(),
            monthStart: month.start,
            createdAt: .now,
            photoCount: photos.count,
            caption: caption,
            assetIdentifiers: photos.map(\.id)
        )
        archives.removeAll { Calendar.current.isDate($0.monthStart, equalTo: month.start, toGranularity: .month) }
        archives.insert(archive, at: 0)
        persistence.saveArchives(archives)
    }

    private static func makeEvents(from photos: [PhotoCandidate], sourceCount: Int) -> [StoryEvent] {
        let groups = Dictionary(grouping: photos, by: \.event)
        let weights = [0.34, 0.18, 0.15, 0.12, 0.11, 0.10]
        return groups.keys.sorted { (groups[$0]?.first?.createdAt ?? .distantPast) < (groups[$1]?.first?.createdAt ?? .distantPast) }
            .enumerated().map { index, name in
                let selected = groups[name] ?? []
                let count = max(selected.count, Int(Double(sourceCount) * weights[index % weights.count]))
                return StoryEvent(name: name, symbol: selected.first?.symbol ?? "photo", sourceCount: count, selectedCount: selected.count)
            }
    }

    private static func addContext(to photos: [PhotoCandidate], calendarMoments: [CalendarMoment], locationNames: [String: String]) -> [PhotoCandidate] {
        photos.map { photo in
            let matchingEvent = calendarMoments
                .filter { $0.matches(photo.createdAt) }
                .sorted { ($0.end.timeIntervalSince($0.start)) < ($1.end.timeIntervalSince($1.start)) }
                .first?.title
            return photo.contextualized(locationName: locationNames[photo.id], calendarEvent: matchingEvent)
        }
    }
}
