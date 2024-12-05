import SwiftUI

@main
struct TimeTrackerApp: App {
    // Shared instance of PersistenceController to manage Core Data
    let persistenceController = PersistenceController.shared
    @StateObject var viewModel: TimeEntryViewModel
    @AppStorage("accentColor") var accentColor: String = "Mint"

    init() {
            let context = persistenceController.container.viewContext
            _viewModel = StateObject(wrappedValue: TimeEntryViewModel(context: context))
        }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext) // Inject Core Data context
                .environmentObject(viewModel) // Inject ViewModel
                .accentColor(Color(accentColor))
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(TimeEntryViewModel(context: PersistenceController.preview.container.viewContext))
    }
}
