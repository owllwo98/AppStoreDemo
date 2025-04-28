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
                    SearchMainView(appList: app)
                case .error(let networkError):
                    Text("\(networkError)")
                }
            }
//            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, placement: .navigationBarDrawer, prompt: "")
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
    }
    
}

extension ItunesSearchView {
    private func handleSearchTextChange() {
            if searchText.isEmpty {
                loadable = .notRequest
            }
        }
        
        private func resetAndSearch() {
            offset = 0
            canLoadMore = true
            loadable = .notRequest
            searchApps()
        }
        
        private func searchApps() {
            guard canLoadMore else { return }
            loadable = .loading
//            Task {
//                container.interactors.itunesSearchInteractor.searchApps(
//                    query: searchText,
//                    offset: offset,
//                    limit: limit,
//                    results: loadableBinding
//                )
//            }
        }
        
        private func loadMoreApps() {
            guard canLoadMore else { return }
            offset += limit
            searchApps()
        }
        
        private func refreshApps() {
            offset = 0
            canLoadMore = true
            searchApps()
        }
}

struct SearchMainView: View {
    var appList: [ItunesSearchResponseDTO]
    
    // Replace single state object with a dictionary of states
    @State private var downloadButtonStates: [String: DownloadButtonState] = [:]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(appList, id: \.bundleId) { item in
                    let buttonStateKey = "downloadButton_\(item.bundleId)"
                    
                    let buttonState = downloadButtonStates[buttonStateKey] ?? {
                        let newState = DownloadButtonState(identifier: buttonStateKey)
                        DispatchQueue.main.async {
                            downloadButtonStates[buttonStateKey] = newState
                        }
                        return newState
                    }()
                    
                    NavigationLink(destination: SearchDetailView(app: item, downloadButtonState: buttonState))  {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .center, spacing: 10) {
                                AsyncImage(url: URL(string: item.artworkUrl60)) { image in
                                    image.resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                } placeholder: {
//                                    ProgressView()
//                                        .frame(width: 60, height: 60)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.trackName)
                                        .font(.headline)
                                    Text(item.genres.first ?? "")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                DownloadButton(
                                    state: buttonState,
                                    title: "받기",
                                    downloadDuration: 30.0,
                                    onDownloadStart: {
                                        print("Download started for \(item.trackName)")
                                    },
                                    onDownloadPause: {
                                        print("Download paused for \(item.trackName)")
                                    },
                                    onDownloadComplete: {
                                        print("Download completed for \(item.trackName)")
                                    }
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
                            
                            screenshotView(screenshotUrls: item.screenshotUrls)
                                .padding(.top, 10)
                        }
                        .padding(.vertical, 10)
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct detailInformationView: View {
    var appList: [ItunesSearchResponseDTO]
    var body: some View {
        HStack {
            
        }
    }
}

struct screenshotView: View {
    var screenshotUrls: [String]
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(screenshotUrls, id: \.self) { item in
                    AsyncImage(url: URL(string: item)) { image in
                        image.resizable()
                            .scaledToFit()
                            .frame(width: UIScreen.main.bounds.width / 3 - 16, height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } placeholder: {
//                        ProgressView()
//                            .frame(width: 30, height: 30)
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
