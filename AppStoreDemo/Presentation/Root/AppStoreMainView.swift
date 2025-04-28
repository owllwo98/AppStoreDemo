//
//  AppStoreMainView.swift
//  AppStoreDemo
//
//  Created by 변정훈 on 4/28/25.
//

import SwiftUI

struct AppStoreMainView: View {
    @Environment(\.injected) private var container: DIContainer
    
    var body: some View {
        TabView {
            Text("오늘의 추천 앱")
                .tabItem {
                    Label("투데이", systemImage: "doc.text.image")
                }
            
            Text("게임")
                .tabItem {
                    Label("게임", systemImage: "gamecontroller")
                }
            
            UserAppListView()
                .tabItem {
                    Label("앱", systemImage: "square.stack.3d.up.fill")
                }
            
            Text("Apple Arcade")
                .tabItem {
                    Label("Arcade", systemImage: "gamecontroller.fill")
                }
            
            ItunesSearchView()
                .tabItem {
                    Label("검색", systemImage: "magnifyingglass")
                }
        }
    }
}
