import SwiftUI

struct WeeklySummaryView: View {
    @State private var weekly: WeeklyAnalytics?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    private static let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if isLoading {
                        ProgressView().padding(.top, 40)
                    } else if let err = errorMessage {
                        Text(err).foregroundStyle(.red).font(.caption).padding()
                    } else if let weekly {
                        caloriesBarChart(weekly.days)
                        weekTotalsCard(weekly)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("This Week")
                        .font(.custom("Georgia-Bold", size: 20))
                }
            }
            .task { await load() }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func caloriesBarChart(_ days: [DayAnalytics]) -> some View {
        let maxCalories = days.map(\.totals.calories).max() ?? 1
        VStack(alignment: .leading, spacing: 12) {
            Text("Calories / Day")
                .font(.custom("Georgia-Bold", size: 18))
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(days, id: \.date) { day in
                    VStack(spacing: 4) {
                        Text("\(Int(day.totals.calories))")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.orange)
                            .frame(
                                width: 32,
                                height: max(4, CGFloat(day.totals.calories / maxCalories) * 120)
                            )
                        Text(dayLabel(day.date))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func weekTotalsCard(_ weekly: WeeklyAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("7-Day Totals")
                    .font(.custom("Georgia-Bold", size: 18))
                Spacer()
                Text("\(weekly.totalMeals) meals").font(.caption).foregroundStyle(.secondary)
            }
            Divider()
            statRow("Calories", "\(Int(weekly.weekTotals.calories)) kcal", .orange)
            statRow("Protein",  "\(Int(weekly.weekTotals.protein))g",    .blue)
            statRow("Carbs",    "\(Int(weekly.weekTotals.carbs))g",      Color(hex: "#FFBF69"))
            statRow("Fats",     "\(Int(weekly.weekTotals.fats))g",       .pink)
            statRow("Others",   "\(Int(weekly.weekTotals.fiber + weekly.weekTotals.sugar))g", .purple)

            Divider()
            let avgCal = weekly.days.isEmpty ? 0 : Int(weekly.weekTotals.calories) / weekly.days.count
            HStack {
                Text("Daily Avg Calories").font(.subheadline)
                Spacer()
                Text("\(avgCal) kcal").font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func statRow(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.subheadline)
            Spacer()
            Text(value).font(.subheadline).foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func dayLabel(_ dateStr: String) -> String {
        guard let date = Self.isoFormatter.date(from: dateStr) else { return dateStr }
        return Self.dayFormatter.string(from: date)
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do { weekly = try await APIService.shared.getWeeklyAnalytics() }
        catch { errorMessage = error.localizedDescription }
        isLoading = false
    }
}
