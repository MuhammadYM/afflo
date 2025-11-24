import CoreData
import SwiftUI

struct MomentumTrendCard: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel: MomentumViewModel
    @Binding var isExpanded: Bool

    init(
        isExpanded: Binding<Bool>,
        viewContext: NSManagedObjectContext? = nil
    ) {
        self._isExpanded = isExpanded
        _viewModel = StateObject(wrappedValue: MomentumViewModel(viewContext: viewContext))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let data = viewModel.momentumData {
                // Score display
                HStack(alignment: .top) {
                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(data.score)")
                            .font(.anonymousPro(size: 32, weight: .bold))
                            .foregroundColor(Color.text(for: colorScheme))

                        Text(data.deltaText)
                            .font(.anonymousPro(size: 12))
                            .foregroundColor(.green)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)

                // Graph
                MomentumLineGraph(dataPoints: data.weeklyPoints, isExpanded: isExpanded)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)

                // Breakdown (only when expanded)
                if isExpanded {
                    MomentumBreakdownView(breakdown: data.breakdown)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 12)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            } else {
                // Loading state
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(height: 180)
            }
        }
        .frame(width: 327)
        .background(Color.background(for: colorScheme))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.tint(for: colorScheme), lineWidth: 1)
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }
        .task {
            await viewModel.loadMomentumData()
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var isExpanded = false

        var body: some View {
            ZStack {
                Color.lightBackground
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("Tap card to expand")
                        .font(.anonymousPro(size: 14))

                    MomentumTrendCard(isExpanded: $isExpanded)
                }
            }
        }
    }

    return PreviewWrapper()
}
