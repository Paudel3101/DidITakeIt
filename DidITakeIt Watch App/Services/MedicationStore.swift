import Foundation
import Combine
import UserNotifications
import WatchKit
import WatchConnectivity

@MainActor
class MedicationStore: NSObject, ObservableObject, WCSessionDelegate {
    @Published var medications: [Medication] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSyncing = false
    
    private var subscriptions: Set<AnyCancellable> = []
    private var wcSession: WCSession?
    
    // CloudKit is disabled - using local storage only
    // To enable CloudKit, add iCloud entitlement in Xcode

    override init() {
        super.init()
        
        // Initialize WatchConnectivity
        activateSession()
        
        // Initialize store with local data
        loadMedicationsLocally()
        
        // Setup auto sync timer for local data
        setupAutoSync()
    }
    
    // MARK: - WatchConnectivity Session
    func activateSession() {
        guard WCSession.isSupported() else {
            print("WCSession not supported")
            return
        }
        
        wcSession = WCSession.default
        wcSession?.delegate = self
        wcSession?.activate()
    }
    
    // WCSessionDelegate methods
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error)")
        } else {
            print("WCSession activated with state: \(activationState)")
            Task { @MainActor in
                self.requestMedicationsFromPhone()
            }
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        if let medications = try? JSONDecoder().decode([Medication].self, from: messageData) {
            Task { @MainActor in
                self.medications = medications
                self.saveMedicationsLocally()
                print("Received \(medications.count) medications from iPhone")
            }
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let medicationsData = message["medications"] as? Data,
           let medications = try? JSONDecoder().decode([Medication].self, from: medicationsData) {
            Task { @MainActor in
                self.medications = medications
                self.saveMedicationsLocally()
                print("Received \(medications.count) medications from iPhone")
            }
        }
        
        // Handle request from iPhone
        if message["request"] as? String == "medications" {
            Task { @MainActor in
                self.sendMedicationsToPhone()
            }
        }
    }
    
    // Handle application context (for background sync)
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        if let medicationsData = applicationContext["medications"] as? Data,
           let medications = try? JSONDecoder().decode([Medication].self, from: medicationsData) {
            Task { @MainActor in
                self.medications = medications
                self.saveMedicationsLocally()
                print("Received \(medications.count) medications from iPhone via application context")
            }
        }
    }
    
    // MARK: - Send to iPhone
    func sendMedicationsToPhone() {
        guard let session = wcSession else {
            print("WCSession not initialized")
            return
        }
        
        guard let data = try? JSONEncoder().encode(medications) else {
            return
        }
        
        if session.isReachable {
            // Use interactive messaging when reachable
            session.sendMessageData(data) { replyData in
                print("Sent medications to iPhone successfully")
            } errorHandler: { error in
                print("Error sending to iPhone: \(error)")
            }
        }
        
        // Use application context for background sync (watchOS always has companion iPhone)
        do {
            try session.updateApplicationContext(["medications": data])
            print("Updated application context for iPhone")
        } catch {
            print("Error updating application context: \(error)")
        }
        
        // Also use transferUserInfo as backup
        session.transferUserInfo(["medications": data])
        print("Transferred medications to iPhone (userInfo)")
    }
    
    // MARK: - Request from iPhone
    func requestMedicationsFromPhone() {
        guard let session = wcSession, session.isReachable else {
            print("iPhone not reachable, using local data")
            return
        }
        
        session.sendMessage(["request": "medications"]) { replyData in
            if let medicationsData = replyData["medications"] as? Data,
               let medications = try? JSONDecoder().decode([Medication].self, from: medicationsData) {
                Task { @MainActor in
                    self.medications = medications
                    self.saveMedicationsLocally()
                    print("Synced \(medications.count) medications from iPhone")
                }
            }
        } errorHandler: { error in
            print("Error requesting from iPhone: \(error)")
        }
    }
    
    // MARK: - Load Medications
    func loadMedications() async {
        isLoading = true
        defer { isLoading = false }
        
        // First try to sync from iPhone
        requestMedicationsFromPhone()
        
        // Using local storage as fallback
        loadMedicationsLocally()
    }
    
    // MARK: - Add Medication
    func addMedication(_ medication: Medication) async {
        var med = medication
        med.id = UUID().uuidString
        
        medications.append(med)
        saveMedicationsLocally()
        
        // Sync to iPhone
        sendMedicationsToPhone()
        
        // Schedule reminder notification
        if med.isReminderEnabled, let reminderTime = med.reminderTime {
            scheduleReminder(for: med, at: reminderTime)
        }
    }
    
    // MARK: - Update Medication
    func updateMedication(_ medication: Medication) async {
        if let index = medications.firstIndex(where: { $0.id == medication.id }) {
            medications[index] = medication
            saveMedicationsLocally()
            
            // Sync to iPhone
            sendMedicationsToPhone()
            
            // Update reminder if needed
            if medication.isReminderEnabled, let reminderTime = medication.reminderTime {
                scheduleReminder(for: medication, at: reminderTime)
            }
        }
    }
    
    // MARK: - Delete Medication
    func deleteMedication(_ medication: Medication) async {
        medications.removeAll { $0.id == medication.id }
        saveMedicationsLocally()
        
        // Sync to iPhone
        sendMedicationsToPhone()
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [medication.id])
    }
    
    // MARK: - Mark as Taken
    func markAsTaken(_ medication: Medication) async {
        var updated = medication
        updated.lastTakenDate = Date()
        updated.lastTakenTime = Date()
        
        await updateMedication(updated)
        
        // Trigger haptic feedback notification
        WKInterfaceDevice.current().play(.success)
    }
    
    // MARK: - Notifications
    func scheduleReminder(for medication: Medication, at time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Time for your medication"
        content.body = medication.name
        content.sound = .default
        
        // Add action buttons
        let taken = UNNotificationAction(identifier: "MARK_TAKEN", title: "Mark Taken", options: [])
        let snooze = UNNotificationAction(identifier: "SNOOZE", title: "Remind in 10 min", options: [])
        let category = UNNotificationCategory(identifier: "MEDICATION_REMINDER", actions: [taken, snooze], intentIdentifiers: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
        
        content.categoryIdentifier = "MEDICATION_REMINDER"
        content.userInfo = ["medicationId": medication.id]
        
        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
        dateComponents.second = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: medication.id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    // MARK: - Local Storage
    private func saveMedicationsLocally() {
        if let encoded = try? JSONEncoder().encode(medications) {
            UserDefaults.standard.set(encoded, forKey: "medications")
        }
    }
    
    private func loadMedicationsLocally() {
        if let data = UserDefaults.standard.data(forKey: "medications"),
           let decoded = try? JSONDecoder().decode([Medication].self, from: data) {
            DispatchQueue.main.async {
                self.medications = decoded
            }
        }
    }
    
    // MARK: - Auto Sync
    private func setupAutoSync() {
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            Task {
                await self.loadMedications()
            }
        }
    }
    
    // MARK: - Check Daily Reset
    func checkAndResetDaily() {
        let lastCheckDate = UserDefaults.standard.object(forKey: "lastResetDate") as? Date ?? Date.distantPast
        
        if !Calendar.current.isDate(lastCheckDate, inSameDayAs: Date()) {
            UserDefaults.standard.set(Date(), forKey: "lastResetDate")
        }
    }
}

