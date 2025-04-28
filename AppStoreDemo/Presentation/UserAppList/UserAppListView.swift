//
//  UserAppListView.swift
//  AppStoreDemo
//
//  Created by 변정훈 on 4/28/25.
//

import SwiftUI
import Combine

struct UserAppListView: View {
    @Environment(\.injected) private var container: DIContainer
    @State private var searchText: String = ""
    @State private var installedApps: [UserApp] = []
    @State private var filteredApps: [UserApp] = []
    private var cancelBag = CancelBag()
    
    var body: some View {
        NavigationStack {
            VStack {
                if filteredApps.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "square.stack.3d.up.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("설치된 앱이 없습니다")
                            .font(.headline)
                        
                        Text("앱 스토어에서 앱을 다운로드하면 여기에 표시됩니다")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredApps) { app in
                            HStack(spacing: 15) {
                                AsyncImage(url: URL(string: app.iconUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 50, height: 50)
                                        .cornerRadius(10)
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(app.name)
                                        .font(.headline)
                                    
                                    Text(formattedDate(app.installedDate))
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    openApp(app.id)
                                }) {
                                    Text("열기")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.blue)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.blue, lineWidth: 1)
                                                .fill(.customGray)
                                        )
                                }
                            }
                            .padding(.vertical, 5)
                        }
                        .onDelete(perform: deleteApps)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("앱")
            .searchable(text: $searchText, placement: .navigationBarDrawer, prompt: "앱, 게임, 스토리 등")
            .onChange(of: searchText) { _, _ in
                filterApps()
            }
            .onAppear {
                loadInstalledApps()
                subscribeToAppStateChanges()
            }
            .onDisappear {
                cancelBag.cancel()
            }
        }
        .tabItem {
            Label("앱", systemImage: "square.stack.3d.up.fill")
        }
    }
    
    private func subscribeToAppStateChanges() {
        container.appState
            .updates(for: \.downloads)
            .sink { _ in
                loadInstalledApps()
            }
            .store(in: cancelBag)
    }
    
    private func loadInstalledApps() {
        let appInfos = container.interactors.downloadInteractor.getAllInstalledAppInfos()
        
        let completedAppIds = container.interactors.downloadInteractor.getCompletedAppIds()
        
        installedApps = appInfos
            .filter { completedAppIds.contains($0.appId) }
            .map { appInfo in
                UserApp(
                    id: appInfo.appId,
                    name: appInfo.appName,
                    iconUrl: appInfo.iconUrl,
                    installedDate: appInfo.installedDate
                )
            }
        
        filterApps()
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.M.d"
        return formatter.string(from: date)
    }
    
    private func filterApps() {
        if searchText.isEmpty {
            filteredApps = installedApps
        } else {
            filteredApps = installedApps.filter { app in
                app.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func deleteApps(at offsets: IndexSet) {
        let appIdsToDelete = offsets.map { filteredApps[$0].id }
        
        filteredApps.remove(atOffsets: offsets)
        
        installedApps.removeAll { app in
            appIdsToDelete.contains(app.id)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for appId in appIdsToDelete {
                container.interactors.downloadInteractor.removeDownload(appId: appId)
            }
        }
    }
    
    private func openApp(_ appId: String) {
        print("앱 열기: \(appId)")
    }
}

struct UserApp: Identifiable, Equatable {
    let id: String
    let name: String
    let iconUrl: String
    let installedDate: Date 
    
    static func == (lhs: UserApp, rhs: UserApp) -> Bool {
        return lhs.id == rhs.id
    }
}

//#Preview {
//    UserAppListView()
//}
