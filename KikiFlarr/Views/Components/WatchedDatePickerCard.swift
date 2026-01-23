import SwiftUI

struct WatchedDatePickerCard: View {
    @Binding var selection: Date
    var title: String = "Date de visionnage"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Label(title, systemImage: "calendar.badge.clock")
                        .font(.headline)
                    Text("Choisissez la date la plus précise possible.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Spacer()

                SelectionBadge(date: selection)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Sélection rapide")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    QuickDateButton(title: "Aujourd'hui", icon: "sun.max.fill") {
                        selection = Date()
                    }

                    QuickDateButton(title: "Hier", icon: "moon.stars.fill") {
                        selection = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Calendrier")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                DatePicker("", selection: $selection, displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .tint(.blue)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.primary.opacity(0.08))
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.06))
        )
        .shadow(color: .black.opacity(0.08), radius: 14, y: 6)
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

private struct SelectionBadge: View {
    let date: Date

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(date.formatted(date: .abbreviated, time: .omitted))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text(date.formatted(.dateTime.weekday(.wide)))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

#Preview {
    WatchedDatePickerCard(selection: .constant(Date()))
        .padding()
}
