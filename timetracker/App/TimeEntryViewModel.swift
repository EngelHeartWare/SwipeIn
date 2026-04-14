import SwiftUI
import Foundation
import CoreData

class TimeEntryViewModel: ObservableObject {
    @Published var entries: [TimeEntry] = []
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        fetchEntries()
    }

    func fetchEntries() {
        let request: NSFetchRequest<TimeEntry> = TimeEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TimeEntry.startTime, ascending: false)]
        do {
            self.entries = try self.context.fetch(request)
        } catch {
            #if DEBUG
            print("Failed to fetch entries: \(error.localizedDescription)")
            #endif
        }
    }

    func updateEntry(_ entry: TimeEntry, newLabel: String, newLocation: String, newStartTime: Date, newEndTime: Date) {
        entry.label = newLabel
        entry.location = newLocation
        entry.startTime = newStartTime
        entry.endTime = newEndTime

        do {
            try context.save()
            objectWillChange.send()
            fetchEntries()
        } catch {
            #if DEBUG
            print("Failed to update entry: \(error.localizedDescription)")
            #endif
        }
    }

    func deleteEntry(_ entry: TimeEntry) {
        context.delete(entry)
        saveChanges()
    }

    private func saveChanges() {
        do {
            try context.save()
            fetchEntries() // Refresh the list after saving.
        } catch {
            #if DEBUG
            print("Failed to save changes:", error.localizedDescription)
            #endif
        }
    }
}


extension TimeEntry {
    convenience init(label: String, location: String, startTime: Date, endTime: Date) {
        self.init()
        self.label = label
        self.location = location
        self.startTime = startTime
        self.endTime = endTime
    }
}
