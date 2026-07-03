//
//  MockAppleDeviceApp.swift
//  MockAppleDevice
//
//  Created by 我勒个去去 on 2026/7/3.
//

import SwiftUI

@main
struct MockAppleDeviceApp: App {
    @AppStorage("app_language") private var appLanguage: String = "zh-Hans"
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, Locale(identifier: appLanguage))
        }
    }
}
