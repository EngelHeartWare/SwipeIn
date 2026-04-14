import SwiftUI
import CoreData
import UniformTypeIdentifiers
import Charts

class ContentViewModel: ObservableObject {
    @Published var showingStats = false
    @Published var selectedTimeFrame: TimeFrame = .today

    // Initialization logic for labels, locations, and entries
    @MainActor
    func initializeData(managedObjectContext: NSManagedObjectContext, labels: [LabelEntry], locations: [LocationEntry], entries: [TimeEntry]) {
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

        // Save the context after initialization
        do {
            try managedObjectContext.save()
        } catch {
            #if DEBUG
            print("Failed to save initial data: \(error.localizedDescription)")
            #endif
        }
    }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var managedObjectContext // Core Data context
    @AppStorage("accentColor") var accentColor: String = "Mint"

    @FetchRequest(sortDescriptors: [SortDescriptor(\TimeEntry.startTime, order: .reverse)])
    private var entries: FetchedResults<TimeEntry>

    @FetchRequest(sortDescriptors: [])
    private var labels: FetchedResults<LabelEntry>

    @FetchRequest(sortDescriptors: [])
    private var locations: FetchedResults<LocationEntry>

    @StateObject private var viewModel = ContentViewModel()
    @StateObject private var mainSectionViewModel = MainSectionViewModel()

    // Control the vertical position of the list
    @State private var listOffset: CGFloat = UIScreen.main.bounds.height
    
    // To track if the list is fully open or closed
    @State private var isListFullyOpen: Bool = false

    @State private var isInitialSetup = true
    
    // Define the height of the partially visible list handle/preview
    // These now represent the *portion* of the screen, not absolute values initially.
    let previewHeight: CGFloat = 100 // The height of the list content visible when closed
    let handleHeight: CGFloat = 40   // Height of the pull-up handle

    @AppStorage("hasSeenTutorial") private var hasSeenTutorial: Bool = false
    @State private var isTutorialVisible: Bool = false

    var body: some View {
        // The single NavigationView should wrap the entire ZStack if you want a global nav bar
        NavigationView {
            GeometryReader { geometry in // <--- IMPORTANT: GeometryReader at the top level
                let fullHeight = geometry.size.height
                let closedPosition = fullHeight - previewHeight - handleHeight // The Y offset when the list is "closed"
                let openPosition: CGFloat = 0 // The Y offset when the list is "fully open" (at the top)
                
                ZStack(alignment: .top) { // Align to top for ZStack content (MainSection at top)
                    // MARK: - Main Section (Background)
                    VStack {
                        MainSection(viewModel: mainSectionViewModel)
                            .frame(maxWidth: .infinity)
                            //.background(Color(UIColor.systemBackground))
                            //.cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                            //.shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                            //.padding(.horizontal)
                            //.padding(.top)

                        Spacer() // Pushes MainSection to the top
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Make sure MainSection fills its background
                    .zIndex(0) // Explicitly set zIndex for clarity, lower value = further back

                    // MARK: - List Section (Overlay, Draggable)
                    // This VStack contains the handle and the scrollable ListSection
                    VStack(spacing: 0) {
                        // Handle
                        HStack {
                            Spacer()
                            Capsule()
                                .frame(width: 60, height: 6)
                                .foregroundColor(.gray.opacity(0.5))
                                .padding(.vertical, 8)
                            Spacer()
                        }
                        .frame(height: handleHeight)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                listOffset = isListFullyOpen ? closedPosition : openPosition
                                isListFullyOpen.toggle()
                            }
                        }

                        // List Content
                        VStack {
                            HorizontalListSection(context: managedObjectContext)
                                .frame(maxWidth: .infinity)
                                .background(Color(UIColor.systemGray5))
                        }
                        // Safety check here to prevent crashes on init
                        .frame(height: max(0, fullHeight - handleHeight))
                    }
                    .background(Color(UIColor.systemGray5))
                    .cornerRadius(20)
                    .shadow(radius: 5)
                    // Apply the offset directly.
                    // Since we initialized listOffset to a large number, it starts at the bottom.
                    .offset(y: listOffset)
                    // Only animate if we are NOT in the initial setup phase to prevent "sliding in" on load
                    .animation(isInitialSetup ? nil : .interactiveSpring(response: 0.5, dampingFraction: 0.8, blendDuration: 0), value: listOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newOffset = listOffset + value.translation.height
                                listOffset = max(openPosition, min(newOffset, closedPosition))
                            }
                            .onEnded { value in
                                let snapThresholdDistance: CGFloat = 80
                                let snapThresholdVelocity: CGFloat = 500
                                let didDragUp = value.translation.height < 0
                                let didDragDown = value.translation.height > 0
                                let dragDistance = abs(value.translation.height)
                                let dragVelocity = abs(value.velocity.height)

                                withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)) {
                                    if didDragUp && (dragDistance > snapThresholdDistance || dragVelocity > snapThresholdVelocity) {
                                        listOffset = openPosition
                                        isListFullyOpen = true
                                    } else if didDragDown && (dragDistance > snapThresholdDistance || dragVelocity > snapThresholdVelocity) {
                                        listOffset = closedPosition
                                        isListFullyOpen = false
                                    } else {
                                        if listOffset < closedPosition / 2 {
                                            listOffset = openPosition
                                            isListFullyOpen = true
                                        } else {
                                            listOffset = closedPosition
                                            isListFullyOpen = false
                                        }
                                    }
                                }
                            }
                    )
                    .zIndex(1)
                    .padding()
                    // MARK: - CRITICAL FIX LOGIC
                    // This updates the position as soon as GeometryReader has the real numbers
                    .onChange(of: closedPosition) { newPosition in
                        if !isListFullyOpen {
                            listOffset = newPosition
                        }
                    }
                    .onAppear {
                        // Ensure we start closed
                        isListFullyOpen = false
                        
                        // Explicitly set the offset to the calculated closed position immediately
                        // Note: We use max(0, ...) to ensure we don't use a bad calculation
                        listOffset = max(0, fullHeight - previewHeight - handleHeight)
                        
                        // Turn off the "setup" flag slightly later to enable animations for user interaction
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isInitialSetup = false
                        }
                    }
                }
                .edgesIgnoringSafeArea(.bottom) // Allow content to extend into the safe area at the bottom
            }
            //.navigationTitle("Swipe In")
            //.navigationBarTitleDisplayMode(.large)
            .background(Color(UIColor.systemBackground)) // Background for the entire view
            .toolbar {
                /*ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: StatsView(entries: Array(entries))) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 18))
                    }
                }*/
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18))
                    }
                }
            }
        } // End of NavigationView
        .onAppear {
            viewModel.initializeData(
                managedObjectContext: managedObjectContext,
                labels: Array(labels),
                locations: Array(locations),
                entries: Array(entries)
            )
        }
        .onAppear {
            if !hasSeenTutorial {
                isTutorialVisible = true
            }
        }
        .overlay(
            Group {
                if isTutorialVisible {
                    TutorialHomeOverlay(isTutorialVisible: $isTutorialVisible)
                        .onAppear {
                            hasSeenTutorial = true
                        }
                }
            }
        )
    }

    // Dynamic background colors (unchanged)
    private var dynamicPrimaryBackground: Color {
        return Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(named: "#1E1E1E") ?? UIColor.systemBackground
            } else {
                return UIColor(named: "#F5F5F5") ?? UIColor.systemBackground
            }
        })
    }

    private var dynamicAccentBackground: Color {
        return Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(named: "#2C2C2C") ?? UIColor.systemGray
            } else {
                return UIColor(named: "#FFFFFF") ?? UIColor.systemGray
            }
        })
    }
}
