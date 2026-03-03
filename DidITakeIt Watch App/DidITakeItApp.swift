//
//  DidITakeItApp.swift
//  DidITakeIt Watch App
//
//  Created by Bishal Paudel on 3/2/26.
//

import SwiftUI
import UserNotifications

@main
struct DidITakeIt_Watch_AppApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            watchOSContentView()
        }
    }
}

class WatchAppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
}
