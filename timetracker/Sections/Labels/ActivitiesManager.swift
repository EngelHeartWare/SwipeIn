import SwiftUI

struct ActivityItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var isPinned: Bool

    init(name: String, isPinned: Bool = false) {
        self.id = UUID()
        self.name = name
        self.isPinned = isPinned
    }
}

struct ActivitiesView: View {
    @State private var activities: [ActivityItem] = []
    @State private var newActivityName: String = ""
    @State private var selectedActivity: String = "Work"
    @AppStorage("accentColor") private var accentColor: String = "Mint"

    var body: some View {
        VStack {
            List {
                if !pinnedActivities.isEmpty {
                    Section(header: Text("Pinned")) {
                        ForEach(pinnedActivities) { activity in
                            activityRow(for: activity)
                        }
                        .onDelete(perform: deletePinnedActivities)
                        .onMove(perform: movePinnedActivities)
                    }
                }

                Section(header: Text("Others")) {
                    ForEach(unpinnedActivities) { activity in
                        activityRow(for: activity)
                    }
                    .onDelete(perform: deleteUnpinnedActivities)
                    .onMove(perform: moveUnpinnedActivities)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .toolbar {
                EditButton()
            }

            HStack {
                TextField("New Activity", text: $newActivityName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Add") {
                    addActivity()
                }
                .disabled(newActivityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .navigationTitle("Activities")
        .onAppear {
            loadActivities()
        }
        .onChange(of: activities) { _ in
            saveActivities()
        }
    }

    private var pinnedActivities: [ActivityItem] {
        activities.filter { $0.isPinned }
    }

    private var unpinnedActivities: [ActivityItem] {
        activities.filter { !$0.isPinned }
    }

    private func activityRow(for activity: ActivityItem) -> some View {
        HStack {
            Text(activity.name)
            Spacer()
            if activity.name == selectedActivity {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color(accentColor))
            }
            Button(action: {
                togglePin(for: activity)
            }) {
                Image(systemName: activity.isPinned ? "pin.fill" : "pin")
                    .foregroundColor(Color(accentColor))
            }
            .buttonStyle(BorderlessButtonStyle()) // Important for buttons inside list rows
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedActivity = activity.name
            UserDefaults.standard.set(selectedActivity, forKey: "selectedActivity")
        }
    }

    private func addActivity() {
        let trimmed = newActivityName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, !activities.map({ $0.name }).contains(trimmed) {
            activities.append(ActivityItem(name: trimmed))
            newActivityName = ""
        }
    }

    private func togglePin(for activity: ActivityItem) {
        if let index = activities.firstIndex(of: activity) {
            activities[index].isPinned.toggle()
        }
    }

    private func deletePinnedActivities(at offsets: IndexSet) {
        let idsToDelete = offsets.map { pinnedActivities[$0].id }
        activities.removeAll { idsToDelete.contains($0.id) }
    }

    private func deleteUnpinnedActivities(at offsets: IndexSet) {
        let idsToDelete = offsets.map { unpinnedActivities[$0].id }
        activities.removeAll { idsToDelete.contains($0.id) }
    }

    private func movePinnedActivities(from source: IndexSet, to destination: Int) {
        var pinned = pinnedActivities
        pinned.move(fromOffsets: source, toOffset: destination)
        reorderActivities(pinned: pinned, unpinned: unpinnedActivities)
    }

    private func moveUnpinnedActivities(from source: IndexSet, to destination: Int) {
        var unpinned = unpinnedActivities
        unpinned.move(fromOffsets: source, toOffset: destination)
        reorderActivities(pinned: pinnedActivities, unpinned: unpinned)
    }

    private func reorderActivities(pinned: [ActivityItem], unpinned: [ActivityItem]) {
        activities = pinned + unpinned
    }

    private func loadActivities() {
        if let data = UserDefaults.standard.data(forKey: "activities"),
           let decoded = try? JSONDecoder().decode([ActivityItem].self, from: data) {
            activities = decoded
        } else {
            // Initial default activities
            activities = [ActivityItem(name: "Work")]
        }
        
        selectedActivity = UserDefaults.standard.string(forKey: "selectedActivity") ?? "Work"
        // fallback
        if !activities.contains(where: { $0.name == selectedActivity }) {
            selectedActivity = activities.first?.name ?? "Work"
        }
    }

    private func saveActivities() {
        if let data = try? JSONEncoder().encode(activities) {
            UserDefaults.standard.set(data, forKey: "activities")
        }

        if !activities.contains(where: { $0.name == selectedActivity }) {
            selectedActivity = activities.first?.name ?? "Work"
            UserDefaults.standard.set(selectedActivity, forKey: "selectedActivity")
        }
    }
}

struct ActivitiesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ActivitiesView()
        }
    }
}
