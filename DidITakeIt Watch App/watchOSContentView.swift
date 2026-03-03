
import SwiftUI
import WatchKit
import Combine

struct watchOSContentView: View {
    @StateObject private var store = MedicationStore()
    @State private var showingAddMedication = false
    @State private var selectedMedication: Medication?
    @State private var currentTime = Date()
    @State private var crownValue: Double = 0
    
    // Timer to update current time every second
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            ZStack {
                if store.medications.isEmpty {
                    emptyStateView
                } else {
                    mainContentView
                }
            }
            .navigationTitle("Did I Take It?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddMedication = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                    }
                    .accessibilityLabel("Add new medication")
                }
            }
        }
        .environmentObject(store)
        .onAppear {
            store.checkAndResetDaily()
            store.activateSession()
        }
        .sheet(isPresented: $showingAddMedication) {
            watchAddMedicationView()
                .environmentObject(store)
        }
        .sheet(item: $selectedMedication) { medication in
            watchMedicationDetailView(medication: medication)
                .environmentObject(store)
        }
    }
    
    // MARK: - Main Content View
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Current Time Display
            currentTimeView
                .padding(.bottom, 8)
            
            // Medications List
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    ForEach(store.medications) { medication in
                        watchMedicationCard(medication)
                    }
                }
                .padding(.horizontal, 8)
            }
            .focusable()
            .digitalCrownRotation($crownValue)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Current Time View
    private var currentTimeView: some View {
        VStack(spacing: 2) {
            Text(currentTime, style: .time)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .monospacedDigit()
                .accessibilityLabel("Current time \(currentTime.formatted(date: .omitted, time: .shortened))")
            
            Text(currentTime, style: .date)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(Color.primary.opacity(0.05))
        .onReceive(timer) { time in
            currentTime = time
        }
    }
    
    // MARK: - Watch Medication Card
    private func watchMedicationCard(_ medication: Medication) -> some View {
        Button(action: {
            selectedMedication = medication
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(medication.name)
                        .font(.system(.body, design: .default))
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                        .accessibilityLabel(medication.name)
                    
                    Text(medication.lastTakenText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .accessibilityHidden(true)
                }
                
                Spacer(minLength: 8)
                
                // Status indicator with accessibility
                HStack(spacing: 4) {
                    Image(systemName: medication.isTakenToday ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(medication.isTakenToday ? .green : .gray)
                    
                    // Text alternative for color-blind users
                    Text(medication.isTakenToday ? "Taken" : "Not taken")
                        .font(.caption2)
                        .foregroundColor(medication.isTakenToday ? .green : .gray)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(medication.isTakenToday ? "\(medication.name), taken today" : "\(medication.name), not taken today")
                .accessibilityAddTraits(medication.isTakenToday ? .isSelected : .isButton)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityAddTraits(.isButton)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            // Current time in empty state too
            VStack(spacing: 2) {
                Text(currentTime, style: .time)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .monospacedDigit()
                    .accessibilityLabel("Current time \(currentTime.formatted(date: .omitted, time: .shortened))")
                
                Text(currentTime, style: .date)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.bottom, 8)
            .onReceive(timer) { time in
                currentTime = time
            }
            
            Spacer()
            
            Image(systemName: "pills")
                .font(.system(size: 44))
                .foregroundColor(.gray)
                .accessibilityHidden(true)
            
            Text("No Medications")
                .font(.system(.body, design: .default))
                .fontWeight(.semibold)
                .accessibilityAddTraits(.header)
            
            Text("Tap + to add")
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityLabel("Tap plus button to add a new medication")
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Detail View
private struct watchMedicationDetailView: View {
    @EnvironmentObject var store: MedicationStore
    @Environment(\.dismiss) var dismiss
    let medication: Medication
    
    @State private var currentMedication: Medication
    @State private var currentTime = Date()
    @State private var crownValue: Double = 0
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init(medication: Medication) {
        self.medication = medication
        self._currentMedication = State(initialValue: medication)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header with Status
                VStack(alignment: .leading, spacing: 8) {
                    Text(currentMedication.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .accessibilityAddTraits(.header)
                    
                    HStack {
                        Image(systemName: currentMedication.isTakenToday ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(currentMedication.isTakenToday ? .green : .gray)
                        
                        // Text alternative for accessibility
                        Text(currentMedication.isTakenToday ? "Taken today" : "Not taken today")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(currentMedication.isTakenToday ? "Status: Taken today" : "Status: Not taken today")
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                
                // Action Button
                if !currentMedication.isTakenToday {
                    Button(action: {
                        Task {
                            await store.markAsTaken(currentMedication)
                            currentMedication.lastTakenDate = Date()
                            currentMedication.lastTakenTime = Date()
                            WKInterfaceDevice.current().play(.success)
                        }
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Mark as Taken")
                        }
                        .font(.system(.body, design: .default))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .accessibilityLabel("Mark \(currentMedication.name) as taken")
                    .accessibilityAddTraits(.isButton)
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Already Taken Today")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(12)
                    .accessibilityLabel("\(currentMedication.name) already taken today")
                }
                
                // Details
                if !currentMedication.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .accessibilityAddTraits(.header)
                        
                        Text(currentMedication.notes)
                            .font(.subheadline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                    .accessibilityLabel("Notes: \(currentMedication.notes)")
                }
                
                if let reminderTime = currentMedication.reminderTime, currentMedication.isReminderEnabled {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text("Reminder")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(reminderTime.formatted(date: .omitted, time: .shortened))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Reminder set for \(reminderTime.formatted(date: .omitted, time: .shortened))")
                }
            }
            .padding()
        .navigationTitle(currentMedication.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Done") { dismiss() }
                .accessibilityLabel("Done, return to main view")
            }
        }
        .focusable()
        .digitalCrownRotation($crownValue)
        .onReceive(timer) { time in
            currentTime = time
        }
    }
}

// MARK: - Add Medication View (Watch)
private struct watchAddMedicationView: View {
    @EnvironmentObject var store: MedicationStore
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var reminderTime: Date = Date()
    @State private var isReminderEnabled = true
    @State private var showTimePicker = false
    @State private var crownValue: Double = 0
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .font(.system(.body, design: .default))
                        .accessibilityLabel("Medication name input")
                } header: {
                    Text("Medication Name")
                        .accessibilityAddTraits(.header)
                }
                
                Section {
                    Toggle("Daily Reminder", isOn: $isReminderEnabled)
                        .accessibilityLabel("Daily reminder toggle")
                    
                    if isReminderEnabled {
                        DatePicker(
                            "Time",
                            selection: $reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .font(.system(.body, design: .default))
                        .accessibilityLabel("Reminder time picker")
                    }
                } header: {
                    Text("Reminder")
                        .accessibilityAddTraits(.header)
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                    .accessibilityLabel("Cancel and return")
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            let med = Medication(
                                name: name,
                                reminderTime: reminderTime,
                                isReminderEnabled: isReminderEnabled
                            )
                            await store.addMedication(med)
                            
                            // Sync to iPhone
                            store.sendMedicationsToPhone()
                            
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                    .accessibilityLabel("Add \(name) medication")
                }
            }
        }
        .focusable()
        .digitalCrownRotation($crownValue)
    }
}

#Preview {
    watchOSContentView()
}

