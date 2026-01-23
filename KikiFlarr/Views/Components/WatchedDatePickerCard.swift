import SwiftUI

struct WatchedDatePickerCard: View {
    @Binding var selection: Date
    var title: String = "Date de visionnage"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Label(title, systemImage: "calendar.badge.clock")
                    .font(.headline)
                Spacer()
                Text(selection.formatted(date: .long, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 8) {
                QuickDateButton(title: "Aujourd'hui", icon: "sun.max.fill") {
                    selection = Date()
                }

                QuickDateButton(title: "Hier", icon: "moon.stars.fill") {
                    selection = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                }
            }

            DatePicker("", selection: $selection, displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(.blue)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.06))
        )
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: selection)
    }
}

private struct QuickDateButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    Capsule()
                        .fill(Color(.tertiarySystemBackground))
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    WatchedDatePickerCard(selection: .constant(Date()))
        .padding()
}
