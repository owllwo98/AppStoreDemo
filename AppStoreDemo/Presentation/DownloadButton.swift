//
//  DownloadButton.swift
//  AppStoreDemo
//
//  Created by 변정훈 on 4/27/25.
//

import SwiftUI
import Combine

struct DownloadButton: View {
    let appId: String
    let title: String
    let downloadDuration: Double
    
    var appName: String?
    var iconUrl: String?
    
    @Environment(\.injected) private var container: DIContainer
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var downloadState: AppState.DownloadsState.AppDownload.DownloadState = .idle
    @State private var downloadProgress: Double = 0.0
    
    @State private var isDownloadRequested: Bool = false
    @State private var isPauseRequested: Bool = false
    @State private var isResumeRequested: Bool = false
    
    var cancelBag = CancelBag()
    
    var body: some View {
        Group {
            switch downloadState {
            case .idle:
                Text(title)
                    .wrapToButton {
                        isDownloadRequested = true
                        downloadState = .downloading
                        downloadProgress = 0.0
                        
                        container.interactors.downloadInteractor.startDownload(
                            appId: appId,
                            duration: downloadDuration
                        )
                    }
                    .asPointBorderText()
                
            case .downloading:
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                        .frame(width: 30, height: 30)
                    
                    Circle()
                        .trim(from: 0, to: downloadProgress)
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(width: 30, height: 30)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: downloadProgress)
                    
                    Image(systemName: "pause.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                }
                .frame(width: 30, height: 30)
                .wrapToButton {
                    isPauseRequested = true
                    downloadState = .paused
                    
                    container.interactors.downloadInteractor.pauseDownload(appId: appId)
                }
                
            case .paused:
                HStack(spacing: 4) {
                    Image(systemName: "icloud.and.arrow.down")
                        .font(.system(size: 14))
                    Text("재개")
                }
                .wrapToButton {
                    isResumeRequested = true
                    downloadState = .downloading
                    
                    container.interactors.downloadInteractor.resumeDownload(
                        appId: appId,
                        duration: downloadDuration
                    )
                }
                .asPointBorderText()
                
            case .completed:
                Text("열기")
                    .wrapToButton {
                        print("앱 열기: \(appId)")
                    }
                    .asPointBorderText()
            case .redownload:
                HStack(spacing: 4) {
                    Image(systemName: "icloud.and.arrow.down")
                        .font(.system(size: 14))
                }
                .wrapToButton {
                    isDownloadRequested = true
                    downloadState = .downloading
                    downloadProgress = 0.0
                    
                    saveAppInfo()
                    
                    container.interactors.downloadInteractor.startDownload(
                        appId: appId,
                        duration: downloadDuration
                    )
                }
                .asPointBorderText()
            }
        }
        .onAppear {
            subscribeToStateChanges()
        }
        .onDisappear {
            cancelBag.cancel()
        }
        .onChange(of: scenePhase) { newPhase, _ in
            if newPhase == .active {
                updateFromAppState()
            }
        }
    }
    
    private func subscribeToStateChanges() {
        updateFromAppState()
        
        container.appState
            .updates(for: \.downloads.appDownloads)
            .sink { appDownloads in
                if let download = appDownloads[appId] {
                    let previousState = downloadState
                    
                    downloadState = download.state
                    downloadProgress = download.progress
                    
                    if previousState != .completed && download.state == .completed {
                        saveAppInfo()
                    }
                }
            }
            .store(in: cancelBag)
    }
    
    private func saveAppInfo() {
        if let appName = appName, let iconUrl = iconUrl {
            container.interactors.downloadInteractor.saveAppInfo(
                appId: appId,
                appName: appName,
                iconUrl: iconUrl
            )
        }
    }
    
    private func updateFromAppState() {
        if let download = container.interactors.downloadInteractor.getDownloadState(for: appId) {
            downloadState = download.state
            downloadProgress = download.progress
            
            if download.state == .completed {
                saveAppInfo()
            }
        } else {
            if container.interactors.downloadInteractor.checkPreviouslyDownloaded(appId: appId) {
                downloadState = .redownload
            } else {
                downloadState = .idle
            }
            downloadProgress = 0.0
        }
    }
}





