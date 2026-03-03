import Foundation
import AppIntents

class SiriIntegrationManager {
    static let shared = SiriIntegrationManager()
    
    /// Donate "Mark as Taken" intent when user takes medication
    func donateMarkAsTakenIntent(medicationName: String) {
        Task {
            let intent = MarkAsTakenIntent()
            intent.medicationName = medicationName  // Property mutation
            do {
                _ = try await intent.perform()
            } catch {
                print("Error performing intent: \(error)")
            }
        }
    }
    
    /// Donate "Get Status" intent when user checks medication
    func donateGetStatusIntent(medicationName: String) {
        Task {
            let intent = GetMedicationStatusIntent()
            intent.medicationName = medicationName  // Property mutation
            do {
                _ = try await intent.perform()
            } catch {
                print("Error performing intent: \(error)")
            }
        }
    }
    
    /// Donate "List Medications" intent when user views all medications
    func donateListMedicationsIntent() {
        Task {
            let intent = ListMedicationsIntent()
            do {
                _ = try await intent.perform()
            } catch {
                print("Error performing intent: \(error)")
            }
        }
    }
}
