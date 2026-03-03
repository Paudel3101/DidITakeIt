import SwiftUI

struct MedicationDetailView: View {
    @EnvironmentObject var store: MedicationStore
    @State var medication: Medication
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Circle()
                            .fill(getColor(medication.color))
                            .frame(width: 60, height: 60)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(medication.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(medication.lastTakenText)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: medication.isTakenToday ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 40))
                            .foregroundColor(medication.isTakenToday ? .green : .gray)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Main Action Button
                if !medication.isTakenToday {
                    Button(action: {
                        Task {
                            await store.markAsTaken(medication)
                        }
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Mark as Taken")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .font(.headline)
                    }
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Already marked as taken today")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(12)
                    .font(.headline)
                }
                
                // Details
                VStack(alignment: .leading, spacing: 16) {
                    Text("Details")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    if !medication.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(medication.notes)
                        }
                    }
                    
                    if medication.isReminderEnabled, let reminderTime = medication.reminderTime {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reminder Time")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.blue)
                                Text(reminderTime.formatted(date: .omitted, time: .shortened))
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func getColor(_ colorName: String) -> Color {
        switch colorName {
        case "red": return .red
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "cyan": return .cyan
        default: return .blue
        }
    }
}

#Preview {
    NavigationStack {
        MedicationDetailView(medication: Medication(name: "Aspirin", color: "blue"))
            .environmentObject(MedicationStore())
    }
}
