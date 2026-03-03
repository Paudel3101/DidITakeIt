import Foundation

struct Medication: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var reminderTime: Date?
    var isReminderEnabled: Bool = true
    var lastTakenDate: Date?
    var lastTakenTime: Date?
    var color: String = "blue" // for UI customization
    var notes: String = ""
    var createdAt: Date = Date()
    var isDeleted: Bool = false
    
    var isTakenToday: Bool {
        guard let lastTakenDate = lastTakenDate else { return false }
        return Calendar.current.isDateInToday(lastTakenDate)
    }
    
    var nextReminderText: String {
        guard let reminderTime = reminderTime else { return "No reminder set" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "Reminder at \(formatter.string(from: reminderTime))"
    }
    
    var lastTakenText: String {
        guard let takenTime = lastTakenTime else { return "Not taken today" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "Taken at \(formatter.string(from: takenTime))"
    }
}
