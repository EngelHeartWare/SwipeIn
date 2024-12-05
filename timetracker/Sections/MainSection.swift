import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import SwiftUI
import CoreData
import UniformTypeIdentifiers

class MainSectionViewModel: ObservableObject {
    @Published var isCheckedIn = false
    @Published var isPaused = false
    @Published var startTime: Date?
}

struct MainSection: View {
    @StateObject var viewModel: MainSectionViewModel
    @Environment(\.managedObjectContext) private var managedObjectContext // Core Data context

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\TimeEntry.startTime, order: .reverse)]
    )
    private var entries: FetchedResults<TimeEntry> // Fetch Core Data entries

    @AppStorage("selectedActivity") private var selectedActivity: String = "Work"
    @AppStorage("selectedPlace") private var selectedPlace: String = "Office"

    var body: some View {
        VStack(spacing: 0) {
            HStack{
                Text("Swipe In")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .padding()
                Spacer()
            }
            SwipeableCheckInOut(
                viewModel: viewModel,
                checkIn: checkIn,
                checkOut: checkOut
            )

            HStack {
                NavigationRow(icon: "rectangle.on.rectangle",
                              title: "\(selectedActivity)",
                              destination: ActivitiesView(),
                              category: NSLocalizedString("Activity", comment: "Category label for activities")
                )
                NavigationRow(icon: "house",
                              title: "\(selectedPlace)",
                              destination: PlacesView(),
                              category: NSLocalizedString("Place", comment: "Category label for places")
                )
            }
            .padding(.bottom, 10)

            Spacer()

            VStack(spacing: 15) {
                CustomNavigationButton(
                    icon: "chart.bar",
                    title: NSLocalizedString("Insights", comment: "Button title for the statistics tab"),
                    destination: StatsView(entries: Array(entries)) // Pass fetched entries to StatsView
                )
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
        .toolbar {
            // Add a settings icon to the top-right corner of the navigation bar
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape.fill") // Settings icon
                        .font(.system(size: 24)) // Optional: to adjust the icon size
                }
            }
        }
    }

    private func checkIn() {
        viewModel.isCheckedIn = true
        viewModel.startTime = Date()
    }

    private func checkOut() {
        guard let startTime = viewModel.startTime else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)) {
            let newEntry = TimeEntry(context: managedObjectContext) // Create a new Core Data entity
            newEntry.startTime = startTime
            newEntry.endTime = Date()
            newEntry.label = selectedActivity
            newEntry.location = selectedPlace

            do {
                try managedObjectContext.save() // Save the context
            } catch {
                print("Failed to save entry: \(error.localizedDescription)")
            }
        }

        viewModel.isCheckedIn = false
        viewModel.startTime = nil
    }
}


struct SwipeableCheckInOut: View {
    @ObservedObject var viewModel: MainSectionViewModel
    let checkIn: () -> Void
    let checkOut: () -> Void
    @State private var dragOffset: CGFloat = 0
    @State private var currentTime = Date()
    let feedback = UIImpactFeedbackGenerator(style: .medium)
    @State private var pausedTime: Date?
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    let leftArrowSymbol = {
        if #available(iOS 16, *) {
            return "arrowshape.left"
        } else {
            return "chevron.left"
        }
    }()

    let rightArrowSymbol = {
        if #available(iOS 16, *) {
            return "arrowshape.right"
        } else {
            return "chevron.right"
        }
    }()
    
    var body: some View {
        Button(action: {
            if viewModel.isCheckedIn {
                    viewModel.isPaused.toggle()
                    if viewModel.isPaused {
                        pausedTime = Date()
                    } else if let pausedAt = pausedTime {
                        let now = Date()
                        viewModel.startTime = viewModel.startTime?.addingTimeInterval(now.timeIntervalSince(pausedAt))
                        currentTime = now // Fix the brief jump-back effect
                        pausedTime = nil
                    }
                }
        }) {
            buttonContent
        }
        .buttonStyle(SwipeableButtonStyle(isCheckedIn: viewModel.isCheckedIn, isPaused: viewModel.isPaused))
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
        .cornerRadius(20)
        .frame(height: 120)
        .padding()
        .onReceive(timer) { _ in
            if !viewModel.isPaused {
                currentTime = Date()
            }
        }
        .accessibilityLabel("Check-in or Check-out button")
        .accessibilityHint(viewModel.isCheckedIn ? "Swipe left to check out" : "Swipe right to check in")
    }
    
    @ViewBuilder
    private var buttonContent: some View {
        HStack {
            if let start = viewModel.startTime, viewModel.isCheckedIn {
                checkedInContent(start: start)
            } else {
                checkedOutContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color.clear)
    }
    
    private func formatDuration(from start: Date) -> String {
        let duration = currentTime.timeIntervalSince(start)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func checkedInContent(start: Date) -> some View {
        ZStack {

            
            HStack {
                Spacer()
                Text(formatDuration(from: start))
                    .foregroundColor(.white.opacity(0.8))
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                Spacer()
            }
            
            HStack {
                Spacer()
                if #available(iOS 16, *) {
                    Image(systemName: leftArrowSymbol)
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .scaleEffect(1 + abs(dragOffset) / 300 * 0.1)
                        .shadow(color: .black.opacity(0.2), radius: abs(dragOffset) / 50, x: 0, y: 0)
                        .animation(.easeOut, value: dragOffset)
                        .offset(x: dragOffset)
                } else {
                    Image(systemName: leftArrowSymbol)
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .offset(x: dragOffset)
                }
            }
            .offset(x: dragOffset)
            .gesture(dragGesture)
            
            if viewModel.isPaused {
                VStack {
                    Spacer()
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white.opacity(0.9))
                        //.padding(.top, 20)
                    Spacer()
                }
            }
        }
    }
    
    private var checkedOutContent: some View {
        ZStack {
            HStack {
                Spacer()
                Text(NSLocalizedString("Swipe", comment: "Prompt for swipe action"))
                    .foregroundColor(.white.opacity(0.8))
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                Spacer()
            }
            HStack {
                if #available(iOS 16, *) {
                    Image(systemName: rightArrowSymbol)
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .scaleEffect(1 + abs(dragOffset) / 300 * 0.1)
                        .shadow(color: .black.opacity(0.2), radius: abs(dragOffset) / 50, x: 0, y: 0)
                        .animation(.easeOut, value: dragOffset)
                        .offset(x: dragOffset)
                } else {
                    Image(systemName: rightArrowSymbol)
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .offset(x: dragOffset)
                }
                Spacer()
            }
            .offset(x: dragOffset)
            .gesture(dragGesture)
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged(handleDragChange)
            .onEnded(handleDragEnd)
    }
    
    private func handleDragChange(value: DragGesture.Value) {
        let maxDrag = UIScreen.main.bounds.width / 3
        let drag = value.translation.width
        let resistanceFactor: CGFloat = 0.5
        
        if (viewModel.isCheckedIn && drag < 0) || (!viewModel.isCheckedIn && drag > 0) {
            dragOffset = drag * (1 - min(abs(drag) / maxDrag, 1) * resistanceFactor)
            dragOffset = min(max(dragOffset, -maxDrag), maxDrag)
        }
    }

    private func handleDragEnd(value: DragGesture.Value) {
        let maxDrag = UIScreen.main.bounds.width / 3
        if abs(value.translation.width) > maxDrag / 2 {
            let feedback = UIImpactFeedbackGenerator(style: .medium)
            feedback.impactOccurred()
            
            withAnimation(.spring()) {
                dragOffset = value.translation.width > 0 ? maxDrag : -maxDrag
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if viewModel.isCheckedIn { checkOut() } else { checkIn() }
                withAnimation { dragOffset = 0 }
            }
        } else {
            withAnimation(.spring()) {
                dragOffset = 0
            }
        }
    }
}


struct SwipeableButtonStyle: ButtonStyle {
    let isCheckedIn: Bool
    let isPaused: Bool
    let feedback = UIImpactFeedbackGenerator(style: .medium)
    @AppStorage("accentColor") var accentColor: String = "Mint"

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(backgroundGradient)
            //.scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            
            /*.onChange(of: configuration.isPressed){
                    feedback.impactOccurred()
            }*/
    }
    
    var backgroundGradient: LinearGradient {
        if isCheckedIn {
            if isPaused {
                return LinearGradient(
                    colors: [
                        //Color(red: 0.0, green: 0.3, blue: 0.3).opacity(0.8),
                          //   Color(red: 0.0, green: 0.3, blue: 0.3)
                        Color(accentColor).darker(by: 20).opacity(0.5), // Makes it 20% darker
                        Color(accentColor).darker(by: 20).opacity(0.8) // Makes it 20% darker

                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
            else{
                return LinearGradient(
                    colors: [
                        //Color(red: 0.0, green: 0.5, blue: 0.5).opacity(0.8),
                            
                        //Color(red: 0.0, green: 0.5, blue: 0.5)
                        Color(accentColor).darker(by: 20).opacity(0.8), // Makes it 20% darker
                        Color(accentColor).darker(by: 20) // Makes it 20% darker

                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        } else {
            
            return LinearGradient(
                colors: [
                            Color(accentColor).opacity(0.6),
                            Color(accentColor).opacity(0.8)
                        ],
                startPoint: .leading,
                endPoint: .trailing
            )
            
        }
    }
}

struct CustomNavigationButton<Destination: View>: View {
    let icon: String
    let title: String
    let destination: Destination
    @Environment(\.colorScheme) var colorScheme

    var backgroundColor: Color {
        colorScheme == .light ? .white : Color(UIColor.systemGray6)
        }
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(.primary)
                Text(title)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 20))
                    .foregroundColor(.primary.opacity(0.7))
            }
            .padding()
            .background(
                .ultraThinMaterial
                //Color(UIColor.systemGray6)
                /*LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                    startPoint: .leading,
                    endPoint: .trailing
                )*/
            )
            .cornerRadius(15)
            //.shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
        }
        .padding(.horizontal)
        .scaleEffect(1.05) // Slightly larger on hover
        .animation(.easeInOut(duration: 0.2), value: true)
    }
}

struct NavigationRow<Destination: View>: View {
    let icon: String
    let title: String
    let destination: Destination
    let category: String
    @Environment(\.colorScheme) var colorScheme

    var backgroundColor: Color {
            colorScheme == .light ? .white : Color(UIColor.systemGray6)
        }
    
    var body: some View {
        NavigationLink(destination: destination) {
            VStack {
                HStack{
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                    Text(category)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.gray)
                    Spacer()
                }
                HStack{
                    Text(title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .padding(.top, 5)
                        .lineLimit(1)            // <-- Allow only one line
                        .truncationMode(.tail)    // <-- Add "..." at the end if too long
                    Spacer()
                }
            }
            .padding()
            .background(
                .ultraThinMaterial
                //Color(UIColor.systemGray6)
                /*LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.white]),
                    startPoint: .leading,
                    endPoint: .trailing
                )*/
            )
            .cornerRadius(12)
            //.shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
        }
        .padding(.horizontal)
    }
}

extension Color {
    func darker(by percentage: CGFloat = 30.0) -> Color {
        return self.adjust(brightnessBy: -abs(percentage))
    }
    
    private func adjust(brightnessBy percentage: CGFloat) -> Color {
        // Convert SwiftUI Color to UIColor
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        // Get HSB values
        if uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            // Adjust brightness
            let newBrightness = max(min(brightness + (percentage/100.0), 1.0), 0.0)
            return Color(hue: hue, saturation: saturation, brightness: newBrightness)
        }
        return self
    }
}
