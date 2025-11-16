import SwiftUI

struct DateScrollView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedDate: Date = Date()

    private let today = Date()
    private let calendar = Calendar.current

    // Generate dates: 3 months past to 3 months future
    private var dates: [Date] {
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: today) ?? today
        let threeMonthsAhead = calendar.date(byAdding: .month, value: 3, to: today) ?? today

        var dateArray: [Date] = []
        var currentDate = threeMonthsAgo

        while currentDate <= threeMonthsAhead {
            dateArray.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return dateArray
    }

    // Get future dates (from tomorrow onwards)
    private var futureDates: [Date] {
        dates.filter { calendar.isDate($0, inSameDayAs: today) == false && $0 > today }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Fixed today (leftmost, largest)
            DateItemView(
                date: today,
                isToday: true,
                isSelected: calendar.isDate(selectedDate, inSameDayAs: today),
                displayIndex: 0
            )
            .onTapGesture {
                selectedDate = today
            }

            // Scrollable future dates with gradient fade
            GeometryReader { geometry in
                ZStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(futureDates.prefix(30).enumerated()), id: \.element) { index, date in
                                DateItemView(
                                    date: date,
                                    isToday: false,
                                    isSelected: calendar.isDate(selectedDate, inSameDayAs: date),
                                    displayIndex: index + 1
                                )
                                .onTapGesture {
                                    selectedDate = date
                                }
                            }
                        }
                        .padding(.trailing, 40)
                    }

                    // Gradient fade on leading (left) edge
                    HStack {
                        LinearGradient(
                            colors: [
                                Color.background(for: colorScheme),
                                Color.background(for: colorScheme).opacity(0.8),
                                Color.background(for: colorScheme).opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 40)
                        .allowsHitTesting(false)

                        Spacer()
                    }

                    // Gradient fade on trailing (right) edge
                    HStack {
                        Spacer()

                        LinearGradient(
                            colors: [
                                Color.background(for: colorScheme).opacity(0),
                                Color.background(for: colorScheme).opacity(0.8),
                                Color.background(for: colorScheme)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 60)
                        .allowsHitTesting(false)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .frame(height: 60)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - DateItemView
private struct DateItemView: View {
    @Environment(\.colorScheme) var colorScheme

    let date: Date
    let isToday: Bool
    let isSelected: Bool
    let displayIndex: Int

    private let calendar = Calendar.current

    // Day name formatter (Thu)
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    // Day number (8)
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    // Month name (Nov)
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }

    var body: some View {
        Group {
            if isToday {
                // Today's date: horizontal layout (day + number) with month below
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(dayName)
                            .font(.montserrat(size: 20, weight: .regular))
                            .foregroundColor(Color.text(for: colorScheme).opacity(0.6))

                        Text(dayNumber)
                            .font(.montserrat(size: 20, weight: .bold))
                            .foregroundColor(Color.text(for: colorScheme))
                    }

                    Text(monthName)
                        .font(.montserrat(size: 10, weight: .regular))
                        .foregroundColor(Color.text(for: colorScheme).opacity(0.6))

                    // Selection underline
                    Rectangle()
                        .fill(Color(hex: "FFA704"))
                        .frame(width: 30, height: 1)
                        .opacity(isSelected ? 1 : 0)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
            } else {
                // Other dates: vertical layout (no month)
                VStack(spacing: 2) {
                    Text(dayName)
                        .font(.montserrat(size: 10, weight: .regular))
                        .foregroundColor(Color.text(for: colorScheme).opacity(0.6))

                    Text(dayNumber)
                        .font(.montserrat(size: 10, weight: .bold))
                        .foregroundColor(Color.text(for: colorScheme))

                    // Selection underline
                    Rectangle()
                        .fill(Color(hex: "FFA704"))
                        .frame(width: 20, height: 1)
                        .opacity(isSelected ? 1 : 0)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
            }
        }
    }
}

#Preview {
    DateScrollView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    DateScrollView()
        .preferredColorScheme(.dark)
}
