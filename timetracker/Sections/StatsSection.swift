import SwiftUI
import Charts

class StatsViewModel: ObservableObject {
    @Published var activityTotals: [(String, TimeInterval)] = []
    @Published var locationTotals: [(String, TimeInterval)] = []
    @Published var totalDuration: TimeInterval = 0
    
    func updateStats(entries: FetchedResults<TimeEntry>, timeFrame: TimeFrame) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let calendar = Calendar.current
            let now = Date()
            let startDate: Date
            
            switch timeFrame {
            case .today:
                startDate = calendar.startOfDay(for: now)
            case .thisWeek:
                startDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            case .thisMonth:
                startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            case .thisYear:
                startDate = calendar.date(from: calendar.dateComponents([.year], from: now))!
            case .overall:
                startDate = Date.distantPast
            }
            
            // You may also consider filtering on the entry.startTime if needed.
            let filteredEntries = entries.lazy.filter { entry in
                // Check if either startTime or endTime falls within the time frame.
                // Here we're checking the entry's endTime against the startDate.
                (entry.endTime ?? Date.distantPast) >= startDate
            }
            
            var activities = [String: TimeInterval]()
            var locations = [String: TimeInterval]()
            var total: TimeInterval = 0
            
            filteredEntries.forEach { entry in
                guard let endTime = entry.endTime, let startTime = entry.startTime else {
                    #if DEBUG
                    print("Skipping entry with missing dates")
                    #endif
                    return
                }
                
                let duration = endTime.timeIntervalSince(startTime)
                activities[entry.label ?? "Activity", default: 0] += duration
                locations[entry.location ?? "Location", default: 0] += duration
                total += duration
            }
            
            let sortedActivities = activities.sorted { $0.value > $1.value }
            let sortedLocations = locations.sorted { $0.value > $1.value }
            
            DispatchQueue.main.async {
                self.activityTotals = sortedActivities
                self.locationTotals = sortedLocations
                self.totalDuration = total
            }
        }
    }
}


struct StatsView: View {
    @StateObject private var viewModel = StatsViewModel()
    @State private var selectedTimeFrame: TimeFrame = .today
    
    @FetchRequest(
            sortDescriptors: [SortDescriptor(\TimeEntry.startTime, order: .reverse)]
        )
    private var entries: FetchedResults<TimeEntry> // This is now correct!

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                TimeFrameMenu(selectedTimeFrame: $selectedTimeFrame)

                DurationList(title: LocalizedStringKey("Activities"), items: viewModel.activityTotals)

                DurationList(title: LocalizedStringKey("Locations"), items: viewModel.locationTotals)

                TotalDurationCard(duration: viewModel.totalDuration)
            }
            .padding()
        }
        .navigationTitle("Insights")
        .background(Color(UIColor.systemGroupedBackground))
        .onAppear {
            viewModel.updateStats(entries: entries, timeFrame: selectedTimeFrame)
        }
        .onChange(of: selectedTimeFrame) { newTimeFrame in
            viewModel.updateStats(entries: entries, timeFrame: selectedTimeFrame)
        }
    }
}

struct TimeFrameMenu: View {
    @Binding var selectedTimeFrame: TimeFrame
    
    var body: some View {
        Menu {
            ForEach(TimeFrame.allCases, id: \.self) { frame in
                Button(frame.localizedString) { // <-- Change here!
                            selectedTimeFrame = frame
                            #if DEBUG
                            print("TimeFrame changed to: \(selectedTimeFrame.localizedString)")
                            #endif
                        }
            }
        } label: {
            HStack {
                Text(selectedTimeFrame.localizedString).tag(selectedTimeFrame)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.down")
                Spacer()
            }
            //.padding()
        }
    }
}

struct TotalDurationCard: View {
    let duration: TimeInterval
    
    var body: some View {
        VStack{
            HStack {
                Text("Total")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(formatDuration(duration))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct DurationList: View {
    let title: LocalizedStringKey // Change String to LocalizedStringKey
    let items: [(String, TimeInterval)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                /*Text(formatDuration(items.map(\.1).reduce(0, +)))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)*/
            }
            .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(items, id: \.0) { item in
                    HStack {
                        Text(item.0)
                            .font(.subheadline)
                        Spacer()
                        Text(formatDuration(item.1))
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

let sharedFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute]
    formatter.unitsStyle = .abbreviated
    return formatter
}()

func formatDuration(_ duration: TimeInterval) -> String {
    return sharedFormatter.string(from: duration) ?? ""
}

enum TimeFrame: String, CaseIterable {
    case today = "today"
    case thisWeek = "thisWeek"
    case thisMonth = "thisMonth"
    case thisYear = "thisYear"
    case overall = "overall"
    
    var localizedString: String {
            switch self {
            case .today:
                return NSLocalizedString("Today", comment: "Time frame filter option for today")
            case .thisWeek:
                return NSLocalizedString("This Week", comment: "Time frame filter option for this week")
            case .thisMonth:
                return NSLocalizedString("This Month", comment: "Time frame filter option for this month")
            case .thisYear:
                return NSLocalizedString("This Year", comment: "Time frame filter option for this year")
            case .overall:
                return NSLocalizedString("Overall", comment: "Time frame filter option for overall time")
            }
        }
}
