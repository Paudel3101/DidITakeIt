import SwiftUI

struct AddMedicationView: View {
    @EnvironmentObject var store: MedicationStore
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var reminderTime: Date?
    @State private var isReminderEnabled = true
    @State private var selectedColor = "blue"
    @State private var notes = ""
    @State private var showColorPicker = false
    @State private var showTimePicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Medication Details") {
                    TextField("Medication Name", text: $name)
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                    
                    HStack {
                        Text("Color")
                        Spacer()
                        Circle()
                            .fill(getColor(selectedColor))
                            .frame(width: 30, height: 30)
                            .onTapGesture {
                                showColorPicker = true
                            }
                    }
                }
                
                Section("Reminder Settings") {
                    Toggle("Enable Reminder", isOn: $isReminderEnabled)
                    
                    if isReminderEnabled {
                        HStack {
                            Text("Time")
                            Spacer()
                            if let time = reminderTime {
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
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task {
                            let medication = Medication(
                                name: name,
                                reminderTime: reminderTime,
                                isReminderEnabled: isReminderEnabled,
                                color: selectedColor,
                                notes: notes
                            )
                            await store.addMedication(medication)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showColorPicker) {
            ColorPickerView(selectedColor: $selectedColor)
        }
        .sheet(isPresented: $showTimePicker) {
            TimePickerView(selectedTime: $reminderTime)
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
    AddMedicationView()
        .environmentObject(MedicationStore())
}
