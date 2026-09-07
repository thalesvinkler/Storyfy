import SwiftUI

struct ReviewView: View {
    @Environment(AppModel.self) private var model
    @State private var mode: ReviewMode = .grid
    @State private var showingSuggestions = false
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 14) {
            header
            eventStrip

            Picker("Modo de edição", selection: $mode) {
                Label("Grade", systemImage: "square.grid.2x2").tag(ReviewMode.grid)
                Label("Ordem", systemImage: "arrow.up.arrow.down").tag(ReviewMode.order)
            }
            .pickerStyle(.segmented)

            if mode == .order { orderList } else { photoGrid }

            if let removed = model.lastRemovedPhoto {
                HStack {
                    Text("Foto removida").font(.caption)
                    Spacer()
                    Button("Desfazer") { model.undoRemove() }.font(.caption.bold())
                }
                .padding(11)
                .background(StoryfyTheme.card, in: RoundedRectangle(cornerRadius: 8))
                .accessibilityLabel("Foto \(removed.id) removida. Desfazer")
            }

            HStack(spacing: 10) {
                Button { showingSuggestions = true } label: {
                    Label("Adicionar", systemImage: "plus").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(model.photos.count >= 20 || model.suggestedPhotos.isEmpty)

                Text("\(model.photos.count)/20").font(.caption.bold()).foregroundStyle(StoryfyTheme.muted)
            }

            Button("Criar legenda") { Task { await model.prepareCaption() } }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(model.photos.isEmpty)
        }
        .padding(20)
        .sheet(isPresented: $showingSuggestions) { SuggestionsView() }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Sua narrativa").font(.largeTitle.bold())
                Text("\(model.photos.count) fotos selecionadas").foregroundStyle(StoryfyTheme.muted)
            }
            Spacer()
        }
    }

    private var eventStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) { ForEach(model.storyEvents) { event in EventPill(event: event) } }
        }
    }

    private var photoGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(model.photos.enumerated()), id: \.element.id) { index, photo in
                    PhotoThumbnail(photo: photo)
                        .aspectRatio(0.78, contentMode: .fit)
                        .overlay(alignment: .topLeading) { coverButton(photo: photo, isCover: index == 0) }
                        .overlay(alignment: .topTrailing) { removeButton(photo) }
                        .overlay(alignment: .bottomTrailing) { score(photo) }
                        .contextMenu {
                            Button { model.makeCover(photo) } label: { Label("Usar como capa", systemImage: "star") }
                            Button(role: .destructive) { model.remove(photo) } label: { Label("Remover", systemImage: "trash") }
                        }
                }
            }
            .padding(.top, 4)
        }
    }

    private var orderList: some View {
        List {
            ForEach(Array(model.photos.enumerated()), id: \.element.id) { index, photo in
                HStack(spacing: 12) {
                    PhotoThumbnail(photo: photo).frame(width: 58, height: 58)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(index == 0 ? "Capa" : "Foto \(index + 1)").font(.subheadline.bold())
                        Text(photo.createdAt, format: .dateTime.day().month(.abbreviated)).font(.caption).foregroundStyle(StoryfyTheme.muted)
                    }
                    Spacer()
                    Image(systemName: "line.3.horizontal").foregroundStyle(StoryfyTheme.muted)
                }
                .swipeActions(edge: .leading) { Button { model.makeCover(photo) } label: { Label("Capa", systemImage: "star.fill") }.tint(StoryfyTheme.gold) }
            }
            .onMove(perform: model.move)
            .onDelete { offsets in offsets.map { model.photos[$0] }.forEach(model.remove) }
        }
        .listStyle(.plain)
        .environment(\.editMode, .constant(.active))
    }

    private func coverButton(photo: PhotoCandidate, isCover: Bool) -> some View {
        Button { model.makeCover(photo) } label: {
            Label(isCover ? "CAPA" : "", systemImage: isCover ? "star.fill" : "star")
                .font(.caption2.bold())
                .padding(6)
                .foregroundStyle(isCover ? Color.black : Color.white)
                .background(isCover ? StoryfyTheme.gold : Color.black.opacity(0.48), in: RoundedRectangle(cornerRadius: 4))
        }
        .padding(5)
        .accessibilityLabel(isCover ? "Foto de capa" : "Definir como capa")
    }

    private func removeButton(_ photo: PhotoCandidate) -> some View {
        Button { model.remove(photo) } label: {
            Image(systemName: "xmark").font(.caption.bold()).padding(7).background(.ultraThinMaterial, in: Circle())
        }
        .padding(5)
        .accessibilityLabel("Remover foto")
    }

    private func score(_ photo: PhotoCandidate) -> some View {
        Text("\(Int(photo.score * 100))").font(.caption2.bold()).foregroundStyle(.white).padding(5)
            .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 4)).padding(5)
    }
}

private enum ReviewMode: Hashable { case grid, order }

private struct EventPill: View {
    let event: StoryEvent
    var body: some View {
        HStack(spacing: 7) {
            Text(event.emoji).font(.title3)
            VStack(alignment: .leading, spacing: 1) {
                Text(event.name).font(.caption.bold())
                Text("\(event.selectedCount) de \(event.sourceCount)").font(.caption2).foregroundStyle(StoryfyTheme.muted)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(StoryfyTheme.card, in: RoundedRectangle(cornerRadius: 6))
    }
}

private struct SuggestionsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(model.suggestedPhotos.prefix(60)) { photo in
                        Button { model.add(photo) } label: {
                            PhotoThumbnail(photo: photo)
                                .aspectRatio(0.78, contentMode: .fit)
                                .overlay(alignment: .bottomTrailing) {
                                    Image(systemName: "plus.circle.fill").font(.title2).foregroundStyle(.white).shadow(radius: 3).padding(6)
                                }
                        }
                        .buttonStyle(.plain)
                        .disabled(model.photos.count >= 20)
                    }
                }
                .padding()
            }
            .navigationTitle("Adicionar fotos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Concluir") { dismiss() } } }
            .safeAreaInset(edge: .bottom) {
                Text("\(model.photos.count) de 20 fotos selecionadas").font(.caption.bold()).padding(12).frame(maxWidth: .infinity).background(.bar)
            }
        }
    }
}
