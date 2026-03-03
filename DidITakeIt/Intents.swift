import AppIntents
import Foundation

// MARK: - Mark as Taken Intent
struct MarkAsTakenIntent: AppIntent {
    static let title: LocalizedStringResource = "Mark Medication as Taken"
    static let description = IntentDescription("Mark your medication as taken for today")
    static let openAppWhenRun = false
    
    @Parameter(title: "Medication Name", description: "The name of the medication")
    var medicationName: String
    
    func perform() async throws -> some IntentResult {
        var medications = loadMedications()
        
        if let index = medications.firstIndex(where: { $0.name.lowercased() == medicationName.lowercased() }) {
            medications[index].lastTakenDate = Date()
            medications[index].lastTakenTime = Date()
            saveMedications(medications)
            
            return .result(value: "Marked \(medicationName) as taken")
        }
        
        return .result(value: "Medication not found")
    }
    
    private func loadMedications() -> [Medication] {
        if let data = UserDefaults.standard.data(forKey: "medications"),
           let decoded = try? JSONDecoder().decode([Medication].self, from: data) {
            return decoded
        }
        return []
    }
    
    private func saveMedications(_ medications: [Medication]) {
        if let encoded = try? JSONEncoder().encode(medications) {
            UserDefaults.standard.set(encoded, forKey: "medications")
        }
    }
}

// MARK: - Get Medication Status Intent
struct GetMedicationStatusIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Medication Status"
    static let description = IntentDescription("Get the status of a medication")
    static let openAppWhenRun = false
    
    @Parameter(title: "Medication Name", description: "The name of the medication")
    var medicationName: String
    
    func perform() async throws -> some IntentResult {
        let medications = loadMedications()
        
        if let medication = medications.first(where: { $0.name.lowercased() == medicationName.lowercased() }) {
            // Safe check without MainActor isolation
            let isTaken: Bool
            if let lastTakenDate = medication.lastTakenDate {
                isTaken = Calendar.current.isDateInToday(lastTakenDate)
            } else {
                isTaken = false
            }
            let status = isTaken ? "Taken today" : "Not taken today"
            return .result(value: status)
        }
        
        return .result(value: "Medication not found")
    }
    
    private func loadMedications() -> [Medication] {
        if let data = UserDefaults.standard.data(forKey: "medications"),
           let decoded = try? JSONDecoder().decode([Medication].self, from: data) {
            return decoded
        }
        return []
    }
}

// MARK: - List All Medications Intent
struct ListMedicationsIntent: AppIntent {
    static let title: LocalizedStringResource = "Get All Medications"
    static let description = IntentDescription("Get list of all medications and their status")
    static let openAppWhenRun = false
    
    func perform() async throws -> some IntentResult {
        let medications = loadMedications()
        
        if medications.isEmpty {
            return .result(value: "No medications added")
        }
        
        let statusList = medications.map { med in
            // Safe check without MainActor isolation
            let isTaken: Bool
            if let lastTakenDate = med.lastTakenDate {
                isTaken = Calendar.current.isDateInToday(lastTakenDate)
            } else {
                isTaken = false
            }
            let status = isTaken ? "✓" : "✗"
            return "\(med.name) \(status)"
        }.joined(separator: ", ")
        
        return .result(value: statusList)
    }
    
    private func loadMedications() -> [Medication] {
        if let data = UserDefaults.standard.data(forKey: "medications"),
           let decoded = try? JSONDecoder().decode([Medication].self, from: data) {
            return decoded
        }
        return []
    }
}
