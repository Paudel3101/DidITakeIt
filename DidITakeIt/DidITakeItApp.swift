//
//  DidITakeItApp.swift
//  DidITakeIt
//
//  Created by Bishal Paudel on 3/2/26.
//

import SwiftUI
import UserNotifications

@main
struct DidITakeItApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            iOSContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set up notification handling
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        completionHandler(.newData)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notifications while app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        if response.actionIdentifier == "MARK_TAKEN" {
            // Handle mark taken action
            if let medicationId = userInfo["medicationId"] as? String {
                // This will be handled by the view when app opens
                UserDefaults.standard.set(medicationId, forKey: "lastNotificationMedicationId")
            }
        } else if response.actionIdentifier == "SNOOZE" {
            // Re-schedule in 10 minutes
        }
        
        completionHandler()
    }
}
