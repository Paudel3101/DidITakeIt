import Foundation
import Combine
import UserNotifications
import UIKit
import WatchConnectivity

@MainActor
class MedicationStore: NSObject, ObservableObject, WCSessionDelegate {
    @Published var medications: [Medication] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isWatchConnected = false
    
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
            print("WCSession not supported on this device")
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
                self.isWatchConnected = session.isReachable
            }
        }
    }
    
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        Task { @MainActor in
            self.isWatchConnected = false
        }
    }
    
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        Task { @MainActor in
            self.isWatchConnected = false
        }
        // Re-activate the session
        WCSession.default.activate()
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isWatchConnected = session.isReachable
            if session.isReachable {
                // Send medications to watch when it becomes reachable
                self.sendMedicationsToWatch()
            }
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        if let medications = try? JSONDecoder().decode([Medication].self, from: messageData) {
            Task { @MainActor in
                self.mergeMedicationsFromWatch(medications)
            }
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        // Handle request from Watch
        if message["request"] as? String == "medications" {
            Task { @MainActor in
                self.sendMedicationsToWatch()
            }
        }
        
        // Handle medications data
        if let medicationsData = message["medications"] as? Data,
           let medications = try? JSONDecoder().decode([Medication].self, from: medicationsData) {
            Task { @MainActor in
                self.mergeMedicationsFromWatch(medications)
            }
        }
    }
    
    // Handle application context (for background sync)
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        if let medicationsData = applicationContext["medications"] as? Data,
           let medications = try? JSONDecoder().decode([Medication].self, from: medicationsData) {
            Task { @MainActor in
                self.mergeMedicationsFromWatch(medications)
                print("Received medications from Watch via application context")
            }
        }
    }
    
    // MARK: - Send to Watch
    func sendMedicationsToWatch() {
        guard let session = wcSession, session.activationState == .activated else {
            print("WCSession not activated")
            return
        }
        
        guard let data = try? JSONEncoder().encode(medications) else {
            return
        }
        
        if session.isReachable {
            // Use interactive messaging when reachable
            session.sendMessageData(data) { replyData in
                print("Sent medications to Watch successfully")
            } errorHandler: { error in
                print("Error sending to Watch: \(error)")
            }
        }
        
        // Always use application context for background sync
        if session.isPaired && session.isWatchAppInstalled {
            do {
                try session.updateApplicationContext(["medications": data])
                print("Updated application context for Watch")
            } catch {
                print("Error updating application context: \(error)")
            }
        }
        
        // Also use transferUserInfo as backup for background delivery
        if session.isPaired {
            session.transferUserInfo(["medications": data])
            print("Transferred medications to Watch (userInfo)")
        }
    }
    
    // MARK: - Merge Medications from Watch
    private func mergeMedicationsFromWatch(_ watchMedications: [Medication]) {
        // Merge strategy: Add medications from Watch that don't exist on iPhone
        // Update existing medications if Watch has newer data
        var updated = false
        
        for watchMed in watchMedications {
            if let index = medications.firstIndex(where: { $0.id == watchMed.id }) {
                // Update existing - prefer the one with more recent lastTakenDate
                if let watchLastTaken = watchMed.lastTakenDate,
                   let iphoneLastTaken = medications[index].lastTakenDate {
                    if watchLastTaken > iphoneLastTaken {
                        medications[index] = watchMed
                        updated = true
                    }
                }
            } else {
                // Add new medication from Watch
                medications.append(watchMed)
                updated = true
            }
        }
        
        if updated {
            saveMedicationsLocally()
            print("Merged medications from Watch")
        }
    }
    
    // MARK: - Load Medications
    func loadMedications() async {
        isLoading = true
        defer { isLoading = false }
        
        // Using local storage
        loadMedicationsLocally()
        
        // Try to sync with Watch
        sendMedicationsToWatch()
    }
    
    // MARK: - Add Medication
    func addMedication(_ medication: Medication) async {
        var med = medication
        med.id = UUID().uuidString
        
        medications.append(med)
        saveMedicationsLocally()
        
        // Sync to Watch
        sendMedicationsToWatch()
        
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
            
            // Sync to Watch
            sendMedicationsToWatch()
            
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
        
        // Sync to Watch
        sendMedicationsToWatch()
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [medication.id])
    }
    
    // MARK: - Mark as Taken
    func markAsTaken(_ medication: Medication) async {
        var updated = medication
        updated.lastTakenDate = Date()
        updated.lastTakenTime = Date()
        
        await updateMedication(updated)
        
        // Trigger haptic feedback notification
        #if os(watchOS)
        WKInterfaceDevice.current().play(.success)
        #else
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
        #endif
    }
    
    // MARK: - Notifications
    func scheduleReminder(for medication: Medication, at time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Time for your medication"
        content.body = medication.name
        content.sound = .default
        content.badge = NSNumber(value: 1)
        
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
            // It's a new day, but don't reset - just track that we've checked
            UserDefaults.standard.set(Date(), forKey: "lastResetDate")
            // Medications stay marked if taken "today" from yesterday's perspective
            // This is handled by the isTakenToday computed property
        }
    }
}

