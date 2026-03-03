import SwiftUI

struct EditMedicationView: View {
    @EnvironmentObject var store: MedicationStore
    @Environment(\.dismiss) var dismiss
    
    @State var medication: Medication
    @State private var showColorPicker = false
    @State private var showTimePicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Medication Details") {
                    TextField("Medication Name", text: $medication.name)
                    
                    TextField("Notes (optional)", text: $medication.notes, axis: .vertical)
                        .lineLimit(3...5)
                    
                    HStack {
                        Text("Color")
                        Spacer()
                        Circle()
                            .fill(getColor(medication.color))
                            .frame(width: 30, height: 30)
                            .onTapGesture {
                                showColorPicker = true
                            }
                    }
                }
                
                Section("Reminder Settings") {
                    Toggle("Enable Reminder", isOn: $medication.isReminderEnabled)
                    
                    if medication.isReminderEnabled {
                        HStack {
                            Text("Time")
                            Spacer()
                            if let time = medication.reminderTime {
                                Text(time.formatted(date: .omitted, time: .shortened))
                                    .foregroundColor(.blue)
                            } else {
                                Text("Not Set")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onTapGesture {
                            showTimePicker = true
                        }
                    }
                }
                
                Section("History") {
                    if let lastTaken = medication.lastTakenTime {
                        HStack {
                            Text("Last Taken")
                            Spacer()
                            Text(lastTaken.formatted(date: .abbreviated, time: .shortened))
                        }
                    } else {
                        Text("Never taken")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        Task {
                            await store.deleteMedication(medication)
                            dismiss()
                        }
                    } label: {
                        Label("Delete Medication", systemImage: "trash.fill")
                    }
                }
            }
            .navigationTitle(medication.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task {
                            await store.updateMedication(medication)
                            dismiss()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showColorPicker) {
            ColorPickerView(selectedColor: $medication.color)
        }
        .sheet(isPresented: $showTimePicker) {
            TimePickerView(selectedTime: $medication.reminderTime)
        }
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
    EditMedicationView(medication: Medication(name: "Aspirin", color: "blue"))
        .environmentObject(MedicationStore())
}
