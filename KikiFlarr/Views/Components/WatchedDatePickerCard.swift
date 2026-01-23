import SwiftUI

struct WatchedDatePickerCard: View {
    @Binding var watchedDate: Date

    var body: some View {
        DatePicker("Date", selection: $watchedDate, displayedComponents: [.date])
            .datePickerStyle(.compact)
    }
}

#Preview {
    Form {
        WatchedDatePickerCard(watchedDate: .constant(Date()))
    }
}
