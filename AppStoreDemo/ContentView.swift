//
//  ContentView.swift
//  AppStoreDemo
//
//  Created by 변정훈 on 4/24/25.
//

import SwiftUI
import Combine

struct ContentView: View {
    
    @Environment(\.injected) private var container: DIContainer
    @StateObject private var appStore: AppStore
    @State private var loadable: Loadable<[ItunesSearchResponseDTO]> = .notRequest
    
    private var loadableBinding: LoadableSubject<[ItunesSearchResponseDTO]> {
        $loadable
    }
    
    init() {
        _appStore = StateObject(wrappedValue: AppStore())
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Network: \(container.appState.value.network.statusDescription)")
            Text("Last Checked: \(container.appState.value.network.lastChecked, style: .date)")
            Text("\(container.interactors.itunesSearchInteractor.searchApps(query: "홍익", results: loadableBinding))")
            
            switch loadable {
            case .notRequest:
                Text("1")
            case .loading:
                Text("2")
            case .success(let t):
                Text("3")
                Text(t.first!.artistViewUrl)
            case .error(let networkError):
                Text("4")
            }
            
        }
        .padding()
        .task {
            container.interactors.itunesSearchInteractor.searchApps(query: "홍익", results: loadableBinding)
        }
        .environmentObject(appStore)
    }
}

//#Preview {
//    ContentView()
//}
