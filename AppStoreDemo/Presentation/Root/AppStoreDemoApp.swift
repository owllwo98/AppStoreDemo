//
//  AppStoreDemoApp.swift
//  AppStoreDemo
//
//  Created by 변정훈 on 4/24/25.
//

import SwiftUI

@main
struct AppStoreDemoApp: App {
    @StateObject private var appStore = AppStore()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .inject(appStore.container)
        }
    }
}
