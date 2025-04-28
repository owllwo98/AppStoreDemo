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
//    @StateObject private var downloadManager: DownloadManager
    
    init() {
        let store = AppStore()
        _appStore = StateObject(wrappedValue: store)
//        _downloadManager = StateObject(wrappedValue: DownloadManager(appState: store.container.appState))
    }
    var body: some Scene {
        WindowGroup {
            ItunesSearchView()
                .inject(appStore.container)
//                .environmentObject(downloadManager)
        }
    }
}
