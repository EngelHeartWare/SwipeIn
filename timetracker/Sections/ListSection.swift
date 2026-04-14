import SwiftUI
import CoreData
import UniformTypeIdentifiers
import Charts

struct ListSection: View {
    @ObservedObject private var viewModel: TimeEntryViewModel
    @Environment(\.managedObjectContext) private var managedObjectContext
    @State private var showingManualEntry = false
    @State private var selectedEntry: TimeEntry?
    @AppStorage("hasSeenListTutorial") private var hasSeenListTutorial: Bool = false
    @State private var isListTutorialVisible: Bool = false
    @Environment(\.dismiss) var dismiss

    init(context: NSManagedObjectContext) {
        _viewModel = ObservedObject(wrappedValue: TimeEntryViewModel(context: context))
    }

    var body: some View {
        NavigationStack {
            ZStack {
           
                        List {
                                LazyVStack {
                                    if viewModel.entries.isEmpty {
                                        
                                        HStack {
                                            Spacer()
                                            Text("Add your first entry")
                                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                                .foregroundColor(.secondary)
                                                .padding(20)
                                            Spacer()
                                        }
                                    }
                                    ForEach(viewModel.entries) { entry in
                                        CardView(entry: entry)
                                            .listRowBackground(Color.clear)
                                            .listRowSeparator(.hidden)
                                            .transition(.opacity)
                                            .onLongPressGesture(minimumDuration: 0.2) {
                                                HapticManager.triggerHaptic()
                                                withAnimation {
                                                    selectedEntry = entry
                                                }
                                            }
                                    }
                                    .onDelete(perform: deleteEntries)
                                }
                                .listRowBackground(Color.clear)
                            
                        }
                        .listStyle(PlainListStyle())
                        .background(Color(.systemGray5))
                    
                }
                .background(Color(.systemGray5))
                .navigationTitle("Entries")
                .navigationBarTitleDisplayMode(.automatic) // Ensures title and buttons are on the same horizontal line
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(NSLocalizedString("Done", comment: "Button to dismiss a modal sheet")) {
                                                dismiss() // <--- NEW ACTION: Dismiss the sheet
                                            }

                    }
                    
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: { showingManualEntry = true }) {
                            Image(systemName: "plus")
                        }
                    }
                    
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: { exportCSV(entries: viewModel.entries) }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }

                .sheet(isPresented: $showingManualEntry) {
                    ManualEntryView(managedObjectContext: managedObjectContext)
                }
                .sheet(item: $selectedEntry) { entry in
                    EditEntryView(entry: entry, viewModel: viewModel)
                    /*.onDisappear {
                     viewModel.fetchEntries() // Refresh list after edit
                     }*/
                }
                .onAppear {
                    // Show the tutorial if it's the user's first time opening this view
                    if !hasSeenListTutorial {
                        isListTutorialVisible = true
                    }
                }
                .overlay(
                    // Show tutorial overlay if needed
                    Group {
                        if isListTutorialVisible {
                            TutorialListOverlay(isListTutorialVisible: $isListTutorialVisible)
                                .onAppear {
                                    // Mark the tutorial as shown once the user dismisses it
                                    hasSeenListTutorial = true
                                }
                        }
                    }
                )
            
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        offsets.map { viewModel.entries[$0] }.forEach { entry in
            viewModel.deleteEntry(entry)
        }
    }
    
    func exportCSV(entries: [TimeEntry]) {
        // 1. Check if there is actually data to export
        guard !entries.isEmpty else {
            #if DEBUG
            print("No entries to export")
            #endif
            // Optionally show an alert to the user here
            return
        }

        var csvString = "Label,Location,Start Time,End Time\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        for entry in entries {
            let label = entry.label ?? "No Label"
            let location = entry.location ?? "No Location"
            let startTime = entry.startTime != nil ? dateFormatter.string(from: entry.startTime!) : "No Start Time"
            let endTime = entry.endTime != nil ? dateFormatter.string(from: entry.endTime!) : "No End Time"
            
            // Clean strings to prevent CSV breakage (remove commas)
            let cleanLabel = label.replacingOccurrences(of: ",", with: " ")
            let cleanLocation = location.replacingOccurrences(of: ",", with: " ")
            
            csvString.append("\(cleanLabel),\(cleanLocation),\(startTime),\(endTime)\n")
        }

        let fileName = "entries.csv"
        
        // Use .cachesDirectory or .temporaryDirectory for exports
        // This avoids cluttering the user's Documents folder permanently
        let path = FileManager.default.temporaryDirectory
        let fileURL = path.appendingPathComponent(fileName)

        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            shareCSV(fileURL: fileURL)
        } catch {
            #if DEBUG
            print("Failed to write CSV file: \(error.localizedDescription)")
            #endif
        }
    }

    func shareCSV(fileURL: URL) {
        let activityController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        
        // This helps find the correct scene/window in modern iOS versions
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            
            // For iPad compatibility (prevents crashing)
            if let popover = activityController.popoverPresentationController {
                popover.sourceView = rootViewController.view
                popover.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootViewController.present(activityController, animated: true, completion: nil)
        }
    }
}

struct ManualEntryView: View {
    let managedObjectContext: NSManagedObjectContext
    @Environment(\.dismiss) var dismiss
    @AppStorage("selectedActivity") private var selectedActivity: String = "Work"
    @AppStorage("selectedPlace") private var selectedPlace: String = "Office"
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Labels")) {
                    HStack {
                        Image(systemName: "rectangle.on.rectangle")
                        NavigationLink(destination: ActivitiesView()) {
                            Text("\(selectedActivity)")
                        }
                    }

                    HStack {
                        Image(systemName: "house")
                        NavigationLink(destination: PlacesView()) {
                            Text("\(selectedPlace)")
                        }
                    }
                }

                Section(header: Text("Start Time")) {
                    DatePicker("Date", selection: $startTime, displayedComponents: [.date])
                    DatePicker("Time", selection: $startTime, displayedComponents: [.hourAndMinute])
                }

                Section(header: Text("End Time")) {
                    DatePicker("Date", selection: $endTime, displayedComponents: [.date])
                    DatePicker("Time", selection: $endTime, displayedComponents: [.hourAndMinute])
                }

                Section {
                    Button("Save Entry") {
                        let newEntry = TimeEntry(context: managedObjectContext)
                        //newEntry.objectWillChange.send()
                        
                        // Ensure end time is after start time
                       guard endTime > startTime else {
                           #if DEBUG
                           print("Invalid entry: end time must be after start time.")
                           #endif
                           return
                       }

                        newEntry.startTime = startTime
                        newEntry.endTime = endTime
                        newEntry.label = selectedActivity.isEmpty ? "Activity" : selectedActivity // Default value for label
                        newEntry.location = selectedPlace.isEmpty ? "Location" : selectedPlace // Default value for location

                        do {
                            try managedObjectContext.save()
                            dismiss()
                        } catch {
                            #if DEBUG
                            print("Failed to save entry: \(error.localizedDescription)")
                            #endif
                        }
                    }
                }
            }
            .navigationTitle(Text(NSLocalizedString("New Manual Entry", comment: "Title for manual entry form")))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct EditEntryView: View {
    @ObservedObject var viewModel: TimeEntryViewModel
    let entry: TimeEntry
    @Environment(\.dismiss) var dismiss

    @State private var startTime: Date
    @State private var endTime: Date
    @State private var editActivity: String
    @State private var editPlace: String
    @AppStorage("accentColor") var accentColor: String = "Mint"

    init(entry: TimeEntry, viewModel: TimeEntryViewModel) {
        self.entry = entry
        self.viewModel = viewModel
        _startTime = State(initialValue: entry.startTime ?? Date())
        _endTime = State(initialValue: entry.endTime ?? Date())
        _editActivity = State(initialValue: entry.label ?? "Work")
        _editPlace = State(initialValue: entry.location ?? "Office")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Labels")) {
                    HStack {
                        Image(systemName: "rectangle.on.rectangle")
                        Text(editActivity)
                    }

                    HStack {
                        Image(systemName: "house")
                        Text(editPlace)
                    }
                }

                Section(header: Text("Start Time")) {
                    DatePicker("Date", selection: $startTime, displayedComponents: [.date])
                    DatePicker("Time", selection: $startTime, displayedComponents: [.hourAndMinute])
                }

                Section(header: Text("End Time")) {
                    DatePicker("Date", selection: $endTime, displayedComponents: [.date])
                    DatePicker("Time", selection: $endTime, displayedComponents: [.hourAndMinute])
                }

                Section {
                    Button("Save Changes") {
                        viewModel.updateEntry(entry, newLabel: editActivity, newLocation: editPlace, newStartTime: startTime, newEndTime: endTime)
                        //viewModel.fetchEntries() // Ensure data reload
                        dismiss()
                    }
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.clear)
                    .foregroundColor(Color(accentColor))
                    .cornerRadius(10)
                }
            }
            .navigationTitle("Edit Entry")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        viewModel.deleteEntry(entry)
                        dismiss()
                    } label: {
                        Label("", systemImage: "trash")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding()
                            //.background(Color.red)
                            .foregroundColor(Color(accentColor))
                            .cornerRadius(10)
                    }
                }
            }
            
            /*.onDisappear {
                print("List appears, reloading entries...")
                //viewModel.fetchEntries()
            }*/
        }
    }
}


struct CardView: View {
    @ObservedObject var entry: TimeEntry // Observes changes
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("accentColor") var accentColor: String = "Mint"

    var backgroundColor: Color {
        colorScheme == .light ? .white : Color(UIColor.systemGray6)
    }

    var body: some View {
        VStack {
            HStack {
                Text("\(entry.label ?? "Activity") in \(entry.location ?? "Location")")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .accessibilityLabel("Activity \(entry.label ?? "Activity") at location \(entry.location ?? "Location")")
                Spacer()
            }
            .padding()

            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    if let startTime = entry.startTime {
                        Text("Date: \(formatDay(startTime))")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .accessibilityLabel("Date \(formatDay(startTime))")
                            .foregroundColor(.secondary)
                        
                        Text("From: \(formatDate(startTime))")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .accessibilityLabel("Start time \(formatDate(startTime))")
                            .foregroundColor(.secondary)
                    }

                    if let endTime = entry.endTime {
                        Text("To: \(formatDate(endTime))")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .accessibilityLabel("End time \(formatDate(endTime))")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()

                Spacer()

                if let startTime = entry.startTime, let endTime = entry.endTime {
                    Text("\(formatDuration(from: startTime, to: endTime))")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Color(accentColor))
                        .accessibilityLabel("Duration \(formatDuration(from: startTime, to: endTime)) hours and minutes")
                        .padding()
                }
            }
        }
        .frame(minWidth: 250, maxHeight: 150, alignment: .leading)
        .background(backgroundColor)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        .padding()
        .accessibilityElement(children: .combine)
    }

    private func formatDuration(from start: Date, to end: Date) -> String {
        let duration = end.timeIntervalSince(start)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return String(format: "%02d:%02d", hours, minutes)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }
}
