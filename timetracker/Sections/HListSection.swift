import SwiftUI
import CoreData
import UniformTypeIdentifiers
import Charts

struct HorizontalListSection: View {
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\TimeEntry.startTime, order: .reverse)],
        animation: .default
    ) private var entries: FetchedResults<TimeEntry> // Fetch Core Data entries
    @Environment(\.managedObjectContext) private var managedObjectContext // Core Data context
    
    @StateObject private var viewModel: TimeEntryViewModel
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: TimeEntryViewModel(context: context))
    }
    
    var body: some View {
        if entries.isEmpty {
            // Empty state: tray icon + "Add your first entry" centered, "All Entries" link at bottom
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(.secondary)
                    Text("Add your first entry")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
                NavigationLink(destination: ListSection(context: managedObjectContext)) {
                    HStack(spacing: 16) {
                        Text("All Entries")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .padding(.bottom, 20)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            // Populated state: entries top-aligned, "All Entries" link pushed to bottom
            VStack(spacing: 0) {
                HStack {
                    Text("Entries")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .padding()
                    Spacer()
                }
                ForEach(entries.prefix(3)) { entry in
                    HCardView(entry: entry)
                        .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                        .id(entry.objectID)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(entry.label ?? "Activity") at \(entry.location ?? "Location")")
                }

                Spacer(minLength: 0)

                NavigationLink(destination: ListSection(context: managedObjectContext)) {
                    HStack(spacing: 16) {
                        Text("All Entries")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .padding(.bottom, 20)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    //}

    private func deleteEntries(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                managedObjectContext.delete(entries[index]) // Delete from Core Data
            }

            do {
                try managedObjectContext.save() // Save changes to Core Data
            } catch {
                #if DEBUG
                print("Failed to delete entries: \(error.localizedDescription)")
                #endif
            }
        }
    }
}

struct HCardView: View {
    @ObservedObject var entry: TimeEntry // Observes changes
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("accentColor") var accentColor: String = "Mint"

    var backgroundColor: Color {
        colorScheme == .light ? .white : Color(UIColor.systemGray6)
    }

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(entry.label ?? "Activity") in \(entry.location ?? "Location")")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .accessibilityLabel("Activity \(entry.label ?? "Activity") at location \(entry.location ?? "Location")")
                
                if let startTime = entry.startTime {
                    Text("\(formatDay(startTime))")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Date \(formatDay(startTime))")
                }

                Spacer()

                HStack {
                    Spacer()
                    if let startTime = entry.startTime, let endTime = entry.endTime {
                        Text("\(formatDuration(from: startTime, to: endTime))")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(Color(accentColor))
                            .accessibilityLabel("Duration \(formatDuration(from: startTime, to: endTime)) hours and minutes")
                    }
                }
            }
            .padding()
        }
        .frame(minWidth: 200, maxHeight: 200, alignment: .leading)
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
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }
}
