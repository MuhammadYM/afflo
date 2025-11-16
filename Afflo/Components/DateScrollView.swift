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

            // Scrollable future dates
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(futureDates.prefix(30).enumerated()), id: \.element) { index, date in
                        DateItemView(
                            date: date,
                            isToday: false,
                            isSelected: calendar.isDate(selectedDate, inSameDayAs: date),
                            displayIndex: index + 1
                        )
                        .opacity(index == 6 ? 0.4 : 1.0) // Fade 7th day
                        .onTapGesture {
                            selectedDate = date
                        }
                    }
                }
                .padding(.trailing, 16)
            }
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

    // Progressive scaling
    private var scale: CGFloat {
        if isToday {
            return 1.0
        }

        switch displayIndex {
        case 1: return 0.95
        case 2: return 0.90
        case 3: return 0.85
        case 4: return 0.80
        case 5: return 0.75
        case 6: return 0.70
        default: return 0.70
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(dayName)
                .font(.anonymousPro(size: isToday ? 14 : 12, weight: .regular))
                .foregroundColor(Color.text(for: colorScheme).opacity(0.6))

            Text(dayNumber)
                .font(.anonymousPro(size: isToday ? 32 : 24, weight: .bold))
                .foregroundColor(Color.text(for: colorScheme))

            Text(monthName)
                .font(.anonymousPro(size: isToday ? 14 : 12, weight: .regular))
                .foregroundColor(Color.text(for: colorScheme).opacity(0.6))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, isToday ? 16 : 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.text(for: colorScheme).opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.text(for: colorScheme) : Color.clear, lineWidth: 1)
        )
        .scaleEffect(scale)
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
