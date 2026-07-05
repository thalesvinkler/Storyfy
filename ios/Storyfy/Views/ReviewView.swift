import SwiftUI

struct ReviewView: View {
    @Environment(AppModel.self) private var model
    @State private var editingOrder = false
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 16) {
            HStack { VStack(alignment: .leading) { Text("Sua história").font(.largeTitle.bold()); Text("\(model.photos.count) momentos escolhidos").foregroundStyle(StoryfyTheme.muted) }; Spacer(); Button(editingOrder ? "Grade" : "Ordenar") { editingOrder.toggle() } }
            if editingOrder {
                List { ForEach(model.photos) { photo in HStack { PhotoThumbnail(photo: photo).frame(width: 62, height: 62); Text(photo.createdAt, format: .dateTime.day().month(.abbreviated)); Spacer(); Image(systemName: "line.3.horizontal") } }.onMove(perform: model.move).onDelete { offsets in offsets.map { model.photos[$0] }.forEach(model.remove) } }.listStyle(.plain).environment(\.editMode, .constant(.active))
            } else {
                ScrollView { LazyVGrid(columns: columns, spacing: 8) { ForEach(model.photos) { photo in PhotoThumbnail(photo: photo).aspectRatio(0.78, contentMode: .fit).overlay(alignment: .topTrailing) { Button { model.remove(photo) } label: { Image(systemName: "xmark").font(.caption.bold()).padding(7).background(.ultraThinMaterial, in: Circle()) }.padding(6) } } } }
            }
            Button("Criar legenda") { model.prepareCaption() }.buttonStyle(PrimaryButtonStyle()).disabled(model.photos.isEmpty)
        }.padding(20)
    }
}
