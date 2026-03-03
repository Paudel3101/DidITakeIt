import ClockKit
import SwiftUI

class ComplicationController: NSObject, CLKComplicationDataSource {
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(
                identifier: "com.conestoga",
                displayName: "Did I Take It?",
                supportedFamilies: [
                    .graphicCircular,
                    .graphicCorner,
                    .graphicRectangular,
                    .modularSmall
                ]
            )
        ]
        handler(descriptors)
    }
    
    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {}
    
    func getLocalizableSampleTemplate(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTemplate?) -> Void
    ) {
        handler(sampleTemplate(for: complication))
    }
    
    func getCurrentTimelineEntry(
        for complication: CLKComplication,
        withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void
    ) {
        if let template = currentTemplate(for: complication) {
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            handler(entry)
        } else {
            handler(nil)
        }
    }
    
    private func getTimelineEntries(
        for complication: CLKComplication,
        after date: Date,
        limit: Int,
        withHandler handler: @escaping ([CLKComplicationTimelineEntry]) -> Void
    ) {
        var entries: [CLKComplicationTimelineEntry] = []
        
        for i in 0..<limit {
            let entryDate = Calendar.current.date(byAdding: .hour, value: i, to: date) ?? date
            if let template = currentTemplate(for: complication, at: entryDate) {
                let entry = CLKComplicationTimelineEntry(date: entryDate, complicationTemplate: template)
                entries.append(entry)
            }
        }
        
        handler(entries)
    }
    
    private func getNextRequestedUpdateDate(withHandler handler: @escaping (Date) -> Void) {
        // Request update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        handler(nextUpdate)
    }
    
    // MARK: - Helper Methods
    
    private func currentTemplate(for complication: CLKComplication, at date: Date = Date()) -> CLKComplicationTemplate? {
        let medications = loadMedications()
        let takenCount = medications.filter { $0.isTakenToday }.count
        let totalCount = medications.count
        
        switch complication.family {
        case .graphicCircular:
            return graphicCircularTemplate(takenCount: takenCount, totalCount: totalCount)
        case .graphicCorner:
            return graphicCornerTemplate(takenCount: takenCount, totalCount: totalCount)
        case .graphicRectangular:
            return graphicRectangularTemplate(takenCount: takenCount, totalCount: totalCount)
        case .modularSmall:
            return modularSmallTemplate(takenCount: takenCount, totalCount: totalCount)
        default:
            return nil
        }
    }
    
    private func sampleTemplate(for complication: CLKComplication) -> CLKComplicationTemplate? {
        switch complication.family {
        case .graphicCircular:
            return graphicCircularTemplate(takenCount: 1, totalCount: 2)
        case .graphicCorner:
            return graphicCornerTemplate(takenCount: 1, totalCount: 2)
        case .graphicRectangular:
            return graphicRectangularTemplate(takenCount: 1, totalCount: 2)
        case .modularSmall:
            return modularSmallTemplate(takenCount: 1, totalCount: 2)
        default:
            return nil
        }
    }
    
    // MARK: - Template Creators
    
    private func graphicCircularTemplate(takenCount: Int, totalCount: Int) -> CLKComplicationTemplate? {
        let gauge = CLKSimpleGaugeProvider(
            style: .ring,
            gaugeColors: [.green],
            gaugeColorLocations: [0.0],
            fillFraction: Float(takenCount) / Float(max(totalCount, 1))
        )
        
        let centerText = CLKSimpleTextProvider(text: "\(takenCount)")
        let bottomText = CLKSimpleTextProvider(text: "of \(totalCount)")
        
        // Use CLKComplicationTemplateGraphicCircularOpenGaugeSimpleText for newer watchOS
        if #available(watchOS 9.0, *) {
            return CLKComplicationTemplateGraphicCircularOpenGaugeRangeText(
                gaugeProvider: gauge,
                leadingTextProvider: centerText,
                trailingTextProvider: bottomText,
                centerTextProvider: CLKSimpleTextProvider(text: "/")
            )
        } else {
            return nil
        }
    }
    
    private func graphicCornerTemplate(takenCount: Int, totalCount: Int) -> CLKComplicationTemplate? {
        let text = CLKSimpleTextProvider(text: "\(takenCount)/\(totalCount)")
        
        if let image = UIImage(systemName: "checkmark.circle.fill") {
            let fullColorImage = CLKFullColorImageProvider(fullColorImage: image)
            
            if #available(watchOS 9.0, *) {
                return CLKComplicationTemplateGraphicCornerTextImage(
                    textProvider: text,
                    imageProvider: fullColorImage
                )
            }
        }
        return nil
    }
    
    private func graphicRectangularTemplate(takenCount: Int, totalCount: Int) -> CLKComplicationTemplate? {
        let headerText = CLKSimpleTextProvider(text: "Did I Take It?")
        let bodyText = CLKSimpleTextProvider(text: "\(takenCount) of \(totalCount) taken")
        
        let gauge = CLKSimpleGaugeProvider(
            style: .ring,
            gaugeColors: [.green],
            gaugeColorLocations: [0.0],
            fillFraction: Float(takenCount) / Float(max(totalCount, 1))
        )
        
        if #available(watchOS 9.0, *) {
            return CLKComplicationTemplateGraphicRectangularTextGauge(
                headerTextProvider: headerText,
                body1TextProvider: bodyText,
                gaugeProvider: gauge
            )
        } else {
            return nil
        }
    }
    
    private func modularSmallTemplate(takenCount: Int, totalCount: Int) -> CLKComplicationTemplate? {
        let text = CLKSimpleTextProvider(text: "\(takenCount)/\(totalCount)")
        
        return CLKComplicationTemplateModularSmallRingText(
            textProvider: text,
            fillFraction: Float(takenCount) / Float(max(totalCount, 1)),
            ringStyle: .closed
        )
    }
    
    // MARK: - Data Loading
    
    private func loadMedications() -> [Medication] {
        if let data = UserDefaults.standard.data(forKey: "medications"),
           let decoded = try? JSONDecoder().decode([Medication].self, from: data) {
            return decoded
        }
        return []
    }
}
