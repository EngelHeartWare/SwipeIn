import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // Ensure the name matches your .xcdatamodeld file
        let modelName = "Model" // Replace with your actual .xcdatamodeld file name
        container = NSPersistentContainer(name: modelName)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("Core Data failed to load persistent store: \(error), \(error.userInfo)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else {
                print("Core Data loaded successfully: \(storeDescription.url?.absoluteString ?? "Unknown URL")")
            }
        }
    }

    // Used only for previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true) // In-memory for preview only
        let context = controller.container.viewContext

        // Add mock data for previews
        for i in 0..<5 {
            let newEntry = TimeEntry(context: context)
            newEntry.startTime = Date().addingTimeInterval(-Double(i * 3600))
            newEntry.endTime = Date().addingTimeInterval(-Double(i * 3600) + 1800)
            newEntry.label = "Work"
            newEntry.location = "Office"
        }

        do {
            try context.save()
        } catch {
            fatalError("Unresolved error \(error)")
        }

        return controller
    }()
}
