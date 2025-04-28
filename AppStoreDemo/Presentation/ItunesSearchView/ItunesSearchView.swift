//
//  ItunesSearchView.swift
//  AppStoreDemo
//
//  Created by 변정훈 on 4/27/25.
//

import SwiftUI
import Combine

struct ItunesSearchView: View {
    @Environment(\.injected) private var container: DIContainer
    @State private var loadable: Loadable<[ItunesSearchResponseDTO]> = .notRequest
    @State private var searchText: String = ""
    @State private var offset: Int = 0
    @State private var canLoadMore: Bool = true
    private let limit: Int = 20
    
    @State private var hasAppearedBefore: Bool = false
    
    private var loadableBinding: LoadableSubject<[ItunesSearchResponseDTO]> {
        $loadable
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                switch loadable {
                case .notRequest:
                    Text("")
                case .loading:
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                case .success(let app):
                    AppRowView(appList: app)
                case .error(let networkError):
                    Text("\(networkError)")
                }
            }
            .navigationTitle("검색")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, placement: .navigationBarDrawer, prompt: "게임, 앱, 스토리 등")
            .onChange(of: searchText) {
                handleSearchTextChange()
            }
            .onSubmit(of: .search) {
                Task {
                    container.interactors.itunesSearchInteractor.searchApps(query: searchText, results: loadableBinding)
                }
            }
        }
        .refreshable {
            Task {
                container.interactors.itunesSearchInteractor.searchApps(query: searchText, results: loadableBinding)
            }
        }
        .onAppear {
            if !hasAppearedBefore && !searchText.isEmpty {
                hasAppearedBefore = true
                Task {
                    container.interactors.itunesSearchInteractor.searchApps(query: searchText, results: loadableBinding)
                }
            }
        }
    }
    
}

extension ItunesSearchView {
    private func handleSearchTextChange() {
        if searchText.isEmpty {
            loadable = .notRequest
        }
    }
}


struct AppRowView: View {
    var appList: [ItunesSearchResponseDTO]
    @Environment(\.injected) private var container: DIContainer
    @State private var downloadStates: [String: AppState.DownloadsState.AppDownload.DownloadState] = [:]
    @State private var visibleApps: [ItunesSearchResponseDTO] = []
    @State private var isLoadingMore = false
    var cancelBag = CancelBag()
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(visibleApps, id: \.bundleId) { item in
                    NavigationLink(destination: SearchDetailView(app: item)) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .center, spacing: 10) {
                                AsyncImage(url: URL(string: item.artworkUrl60)) { image in
                                    image.resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 60, height: 60)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.trackName)
                                        .font(.headline)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                    Text(item.genres.first ?? "")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                DownloadButton(
                                    appId: item.bundleId,
                                    title: "받기",
                                    downloadDuration: 30.0,
                                    appName: item.trackName,
                                    iconUrl: item.artworkUrl60
                                )
                            }
                            .padding(.horizontal)
                            
                            HStack(alignment: .center) {
                                Text("iOS")
                                Text(item.minimumOsVersion)
                                Spacer()
                                Image(systemName: "person.crop.square")
                                Text(item.sellerName)
                                Spacer()
                                Text(item.primaryGenreName)
                            }
                            .font(.caption)
                            .padding(.horizontal)
                            
                            if !isAppDownloadCompleted(appId: item.bundleId) {
                                ScreenshotView(screenshotUrls: item.screenshotUrls)
                                    .padding(.top, 10)
                            }
                        }
                        .padding(.vertical, 10)
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .buttonStyle(PlainButtonStyle())
                
                if visibleApps.count < appList.count {
                    ProgressView()
                        .onAppear {
                            loadMoreContent()
                        }
                        .padding()
                }
            }
        }
        .onAppear {
            loadInitialContent()
            updateDownloadStates()
            subscribeToDownloadChanges()
        }
        .onDisappear {
            cancelBag.cancel()
        }
    }
    
    private func loadInitialContent() {
        guard visibleApps.isEmpty else { return }
        
        visibleApps = Array(appList.prefix(5))
    }
    
    private func loadMoreContent() {
        guard !isLoadingMore && visibleApps.count < appList.count else { return }
        
        isLoadingMore = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let nextBatch = appList.dropFirst(visibleApps.count).prefix(5)
            visibleApps.append(contentsOf: nextBatch)
            isLoadingMore = false
        }
    }
    
    private func isAppDownloadCompleted(appId: String) -> Bool {
        if let state = downloadStates[appId] {
            return state == .completed
        }
        
        if let downloadState = container.interactors.downloadInteractor.getDownloadState(for: appId) {
            return downloadState.state == .completed
        }
        
        return false
    }
    
    private func updateDownloadStates() {
        for app in visibleApps {
            if let state = container.interactors.downloadInteractor.getDownloadState(for: app.bundleId) {
                downloadStates[app.bundleId] = state.state
            }
        }
    }
    
    private func subscribeToDownloadChanges() {
        container.appState
            .updates(for: \.downloads.appDownloads)
            .sink { appDownloads in
                for app in visibleApps {
                    if let download = appDownloads[app.bundleId] {
                        downloadStates[app.bundleId] = download.state
                    }
                }
            }
            .store(in: cancelBag)
    }
}

struct detailInformationView: View {
    var appList: [ItunesSearchResponseDTO]
    var body: some View {
        HStack {
            
        }
    }
}

struct ScreenshotView: View {
    var screenshotUrls: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                ForEach(screenshotUrls.prefix(5), id: \.self) { item in
                    AsyncImage(url: URL(string: item)) { phase in
                        switch phase {
                        case .empty:
                            Color.gray.opacity(0.2)
                                .frame(width: UIScreen.main.bounds.width / 3 - 16, height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        case .success(let image):
                            image.resizable()
                                .scaledToFit()
                                .frame(width: UIScreen.main.bounds.width / 3 - 16, height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        case .failure:
                            Color.gray.opacity(0.2)
                                .frame(width: UIScreen.main.bounds.width / 3 - 16, height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

//#Preview {
//    ItunesSearchView()
//}
