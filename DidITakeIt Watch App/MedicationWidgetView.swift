import SwiftUI
import WidgetKit

struct MedicationWidgetView: View {
    let medications: [Medication]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Did I Take It?")
                    .font(.headline)
                Spacer()
                Image(systemName: "pills.fill")
                    .foregroundColor(.blue)
            }
            
            if medications.isEmpty {
                Text("No medications")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(medications.prefix(3)) { med in
                    HStack {
                        Text(med.name)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: med.isTakenToday ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(med.isTakenToday ? .green : .gray)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
    }
}

private func loadMedications() -> [Medication] {
    if let data = UserDefaults.standard.data(forKey: "medications"),
       let decoded = try? JSONDecoder().decode([Medication].self, from: data) {
        return decoded
    }
    return []
}
