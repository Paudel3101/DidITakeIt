
import SwiftUI
import UserNotifications

struct iOSContentView: View {
    @StateObject private var store = MedicationStore()
    @State private var showingAddMedication = false
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            homeView
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // Medications Tab
            medicationsView
                .tabItem {
                    Label("Medications", systemImage: "pills.fill")
                }
                .tag(1)
            
            // Statistics Tab
            statisticsView
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(2)
        }
        .environmentObject(store)
        .onAppear {
            requestNotificationPermission()
            store.checkAndResetDaily()
        }
    }
    
    // MARK: - Home View
    private var homeView: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Today")
                            .font(.system(size: 32, weight: .bold))
                            .accessibilityAddTraits(.header)
                        
                        Text(Date().formatted(date: .abbreviated, time: .omitted))
                            .foregroundColor(.secondary)
                            .accessibilityHidden(true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Quick Status Cards
                    if store.medications.isEmpty {
                        emptyStateView
                    } else {
                        VStack(spacing: 12) {
                            ForEach(store.medications) { med in
                                medicationStatusCard(med)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddMedication = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                    .accessibilityLabel("Add new medication")
                }
            }
        }
        .sheet(isPresented: $showingAddMedication) {
            AddMedicationView()
                .environmentObject(store)
        }
    }
    
    // MARK: - Medications Tab
    private var medicationsView: some View {
        NavigationStack {
            List {
                ForEach(store.medications) { med in
                    NavigationLink(destination: EditMedicationView(medication: med).environmentObject(store)) {
                        medicationListRow(med)
                    }
                }
                .onDelete { indices in
                    // Safely delete medications with bounds checking
                    let medicationsToDelete = indices.compactMap { index -> Medication? in
                        guard index >= 0 && index < store.medications.count else { return nil }
                        return store.medications[index]
                    }
                    Task {
                        for medication in medicationsToDelete {
                            await store.deleteMedication(medication)
                        }
                    }
                }
            }
            .navigationTitle("Medications")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddMedication = true }) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add medication")
                }
            }
        }
        .sheet(isPresented: $showingAddMedication) {
            AddMedicationView()
                .environmentObject(store)
        }
    }
    
    // MARK: - Statistics Tab
    private var statisticsView: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Adherence")
                            .font(.title2)
                            .fontWeight(.bold)
                            .accessibilityAddTraits(.header)
                        
                        ForEach(store.medications) { med in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(med.name)
                                        .fontWeight(.semibold)
                                        .accessibilityLabel("\(med.name): \(med.isTakenToday ? "taken" : "not taken")")
                                    
                                    Spacer()
                                    
                                    // Text alternative for color
                                    Text(med.isTakenToday ? "✓" : "✗")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(med.isTakenToday ? .green : .red)
                                }
                                .accessibilityElement(children: .combine)
                                
                                HStack {
                                    ProgressView(value: med.isTakenToday ? 1.0 : 0.0)
                                        .tint(med.isTakenToday ? .green : .gray)
                                }
                                .accessibilityHidden(true)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Statistics")
        }
    }
    
    // MARK: - Helper Views
    private func medicationStatusCard(_ medication: Medication) -> some View {
        NavigationLink(destination: MedicationDetailView(medication: medication).environmentObject(store)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(medication.name)
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                        
                        Text(medication.lastTakenText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .accessibilityHidden(true)
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(medication.isTakenToday ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                            .frame(width: 70, height: 70)
                        
                        VStack {
                            Image(systemName: medication.isTakenToday ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 32))
                                .foregroundColor(medication.isTakenToday ? .green : .gray)
                        }
                        .accessibilityHidden(true)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(medication.name), \(medication.isTakenToday ? "taken today" : "not taken today")")
                
                Button(action: {
                    Task {
                        await store.markAsTaken(medication)
                    }
                }) {
                    Text(medication.isTakenToday ? "Already Taken" : "Mark as Taken")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(medication.isTakenToday ? Color.green.opacity(0.1) : Color.blue)
                        .foregroundColor(medication.isTakenToday ? .green : .white)
                        .cornerRadius(8)
                        .fontWeight(.semibold)
                }
                .disabled(medication.isTakenToday)
                .accessibilityLabel(medication.isTakenToday ? "\(medication.name) already taken" : "Mark \(medication.name) as taken")
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
    }
    
    private func medicationListRow(_ medication: Medication) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(medication.name)
                    .fontWeight(.semibold)
                    .accessibilityAddTraits(.isHeader)
                
                Text(medication.nextReminderText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
            
            Spacer()
            
            // Combined icon with text for accessibility
            HStack(spacing: 4) {
                Image(systemName: medication.isTakenToday ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(medication.isTakenToday ? .green : .gray)
                
                Text(medication.isTakenToday ? "Taken" : "Not taken")
                    .font(.caption)
                    .foregroundColor(medication.isTakenToday ? .green : .gray)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(medication.isTakenToday ? "Taken" : "Not taken")
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "pills")
                .font(.system(size: 60))
                .foregroundColor(.gray)
                .accessibilityHidden(true)
            
            Text("No Medications")
                .font(.title3)
                .fontWeight(.semibold)
                .accessibilityAddTraits(.header)
            
            Text("Add your first medication to get started")
                .foregroundColor(.secondary)
                .accessibilityLabel("No medications added yet. Add your first medication to get started.")
            
            Button(action: { showingAddMedication = true }) {
                Label("Add Medication", systemImage: "plus.circle.fill")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .accessibilityLabel("Add your first medication")
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
}

#Preview {
    iOSContentView()
}

