import SwiftUI
import CoreData
import UniformTypeIdentifiers
import Charts

class ContentViewModel: ObservableObject {
    @Published var showingStats = false
    @Published var selectedTimeFrame: TimeFrame = .today

    // Initialization logic for labels, locations, and entries
    @MainActor
    func initializeData(managedObjectContext: NSManagedObjectContext, labels: [LabelEntry], locations: [LocationEntry], entries: [TimeEntry]) async {
        await MainActor.run {
            // Initialize default labels if none exist
            if labels.isEmpty {
                ["Work", "Leisure"].forEach { labelName in
                    let newLabel = LabelEntry(context: managedObjectContext)
                    newLabel.name = labelName
                }
            }

            // Initialize default locations if none exist
            if locations.isEmpty {
                ["Home", "Office", "Gym"].forEach { locationName in
                    let newLocation = LocationEntry(context: managedObjectContext)
                    newLocation.name = locationName
                }
            }

            // Initialize a default entry if none exist
            /*if entries.isEmpty {
                let newEntry = TimeEntry(context: managedObjectContext)
                newEntry.startTime = Date()
                newEntry.endTime = Date().addingTimeInterval(3600)
                

            }*/

            // Save the context after initialization
            do {
                try managedObjectContext.save()
            } catch {
                print("Failed to save initial data: \(error.localizedDescription)")
            }
        }
    }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var managedObjectContext // Core Data context
    @AppStorage("accentColor") var accentColor: String = "Mint"

    // Fetch requests for Core Data entities
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\TimeEntry.startTime, order: .reverse)]
    ) private var entries: FetchedResults<TimeEntry>

    @FetchRequest(
        sortDescriptors: []
    ) private var labels: FetchedResults<LabelEntry>

    @FetchRequest(
        sortDescriptors: []
    ) private var locations: FetchedResults<LocationEntry>

    @StateObject private var viewModel = ContentViewModel()
    @StateObject private var mainSectionViewModel = MainSectionViewModel()

    @AppStorage("hasSeenTutorial") private var hasSeenTutorial: Bool = false
    @State private var isTutorialVisible: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack{
                Color(UIColor.systemGray5)

                VStack {
                    MainSection(
                        viewModel: mainSectionViewModel
                    )
                    //.shadow(color: Color.black.opacity(0.2), radius: 5)
                    
                    
                    
                    Spacer()
                    
                    HorizontalListSection(context: managedObjectContext)
                        .frame(maxHeight: 200)
                        .background(Color(UIColor.systemGray5))
                    
                }
                //.navigationTitle("Swipe In")
            }
            .background(Color(UIColor.systemBackground))
        }
        .task {
            await viewModel.initializeData(
                managedObjectContext: managedObjectContext,
                labels: Array(labels),
                locations: Array(locations),
                entries: Array(entries)
            )
        }
        .onAppear {
                    // Show the tutorial if it's the user's first time opening this view
                    if !hasSeenTutorial {
                        isTutorialVisible = true
                    }
                }
                .overlay(
                    // Show tutorial overlay if needed
                    Group {
                        if isTutorialVisible {
                            TutorialHomeOverlay(isTutorialVisible: $isTutorialVisible)
                                .onAppear {
                                    // Mark the tutorial as shown once the user dismisses it
                                    hasSeenTutorial = true
                                }
                        }
                    }
                )
    }

    // Dynamic background colors for light and dark mode
    private var dynamicPrimaryBackground: Color {
        return Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(named: "#1E1E1E") ?? UIColor.systemBackground // Fallback to system background
            } else {
                return UIColor(named: "#F5F5F5") ?? UIColor.systemBackground // Fallback to system background
            }
        })
    }

    private var dynamicAccentBackground: Color {
        return Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(named: "#2C2C2C") ?? UIColor.systemGray // Fallback to system gray
            } else {
                return UIColor(named: "#FFFFFF") ?? UIColor.systemGray // Fallback to system gray
            }
        })
    }
}
