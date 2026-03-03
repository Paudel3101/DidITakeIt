import SwiftUI

struct TimePickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedTime: Date?
    
    @State private var hour: Int
    @State private var minute: Int
    
    init(selectedTime: Binding<Date?>) {
        self._selectedTime = selectedTime
        
        // Initialize hour and minute from the bound date if available
        let calendar = Calendar.current
        if let date = selectedTime.wrappedValue {
            let components = calendar.dateComponents([.hour, .minute], from: date)
            self._hour = State(initialValue: components.hour ?? 8)
            self._minute = State(initialValue: components.minute ?? 0)
        } else {
            self._hour = State(initialValue: 8)
            self._minute = State(initialValue: 0)
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Reminder Time")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                VStack {
                    Text("Hour")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("Hour", selection: $hour) {
                        ForEach(0..<24, id: \.self) { h in
                            Text(String(format: "%02d", h))
                                .tag(h)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                
                Text(":")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack {
                    Text("Minute")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("Minute", selection: $minute) {
                        ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { m in
                            Text(String(format: "%02d", m))
                                .tag(m)
                        }
                    }
                    .pickerStyle(.wheel)
                }
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    selectedTime = nil
                    dismiss()
                }) {
                    Text("Remove")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Button(action: {
                    var components = DateComponents()
                    components.hour = hour
                    components.minute = minute
                    selectedTime = Calendar.current.date(from: components) ?? Date()
                    dismiss()
                }) {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
    }
}
