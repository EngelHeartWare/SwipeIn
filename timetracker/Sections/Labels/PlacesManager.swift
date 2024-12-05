import SwiftUI

struct PlaceItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var isPinned: Bool

    init(name: String, isPinned: Bool = false) {
        self.id = UUID()
        self.name = name
        self.isPinned = isPinned
    }
}

struct PlacesView: View {
    @State private var places: [PlaceItem] = []
    @State private var selectedPlace: String = "Office"
    @State private var newPlaceName: String = ""
    @AppStorage("accentColor") private var accentColor: String = "Mint"

    var body: some View {
        VStack {
            List {
                if !pinnedPlaces.isEmpty {
                    Section(header: Text("Pinned")) {
                        ForEach(pinnedPlaces) { place in
                            placeRow(for: place)
                        }
                        .onDelete(perform: deletePinnedPlaces)
                        .onMove(perform: movePinnedPlaces)
                    }
                }

                Section(header: Text("Others")) {
                    ForEach(unpinnedPlaces) { place in
                        placeRow(for: place)
                    }
                    .onDelete(perform: deleteUnpinnedPlaces)
                    .onMove(perform: moveUnpinnedPlaces)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .toolbar {
                EditButton()
            }

            HStack {
                TextField("New Place", text: $newPlaceName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Add") {
                    addPlace()
                }
                .disabled(newPlaceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .navigationTitle("Places")
        .onAppear {
            loadPlaces()
        }
        .onChange(of: places) { _ in
            savePlaces()
        }
    }

    private var pinnedPlaces: [PlaceItem] {
        places.filter { $0.isPinned }
    }

    private var unpinnedPlaces: [PlaceItem] {
        places.filter { !$0.isPinned }
    }

    private func placeRow(for place: PlaceItem) -> some View {
        HStack {
            Text(place.name)
            Spacer()
            if place.name == selectedPlace {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color(accentColor))
            }
            Button(action: {
                togglePin(for: place)
            }) {
                Image(systemName: place.isPinned ? "pin.fill" : "pin")
                    .foregroundColor(Color(accentColor))
            }
            .buttonStyle(BorderlessButtonStyle()) // Important inside lists
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedPlace = place.name
            UserDefaults.standard.set(selectedPlace, forKey: "selectedPlace")
        }
    }

    private func addPlace() {
        let trimmed = newPlaceName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, !places.map({ $0.name }).contains(trimmed) {
            places.append(PlaceItem(name: trimmed))
            newPlaceName = ""
        }
    }

    private func togglePin(for place: PlaceItem) {
        if let index = places.firstIndex(of: place) {
            places[index].isPinned.toggle()
        }
    }

    private func deletePinnedPlaces(at offsets: IndexSet) {
        let idsToDelete = offsets.map { pinnedPlaces[$0].id }
        places.removeAll { idsToDelete.contains($0.id) }
    }

    private func deleteUnpinnedPlaces(at offsets: IndexSet) {
        let idsToDelete = offsets.map { unpinnedPlaces[$0].id }
        places.removeAll { idsToDelete.contains($0.id) }
    }

    private func movePinnedPlaces(from source: IndexSet, to destination: Int) {
        var pinned = pinnedPlaces
        pinned.move(fromOffsets: source, toOffset: destination)
        reorderPlaces(pinned: pinned, unpinned: unpinnedPlaces)
    }

    private func moveUnpinnedPlaces(from source: IndexSet, to destination: Int) {
        var unpinned = unpinnedPlaces
        unpinned.move(fromOffsets: source, toOffset: destination)
        reorderPlaces(pinned: pinnedPlaces, unpinned: unpinned)
    }

    private func reorderPlaces(pinned: [PlaceItem], unpinned: [PlaceItem]) {
        places = pinned + unpinned
    }

    private func loadPlaces() {
        if let data = UserDefaults.standard.data(forKey: "places"),
           let decoded = try? JSONDecoder().decode([PlaceItem].self, from: data) {
            places = decoded
        } else {
            // Default place
            places = [PlaceItem(name: "Office")]
        }

        selectedPlace = UserDefaults.standard.string(forKey: "selectedPlace") ?? "Office"
        // fallback
        if !places.contains(where: { $0.name == selectedPlace }) {
            selectedPlace = places.first?.name ?? "Office"
        }
    }

    private func savePlaces() {
        if let data = try? JSONEncoder().encode(places) {
            UserDefaults.standard.set(data, forKey: "places")
        }

        // 🔥 If the selectedPlace no longer exists, fix it
        if !places.contains(where: { $0.name == selectedPlace }) {
            selectedPlace = places.first?.name ?? "Office"
            UserDefaults.standard.set(selectedPlace, forKey: "selectedPlace")
        }
    }
}

struct PlacesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PlacesView()
        }
    }
}
