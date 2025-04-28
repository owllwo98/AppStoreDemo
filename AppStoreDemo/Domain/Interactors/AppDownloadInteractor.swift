//
//  AppDownloadInteractor.swift
//  AppStoreDemo
//
//  Created by 변정훈 on 4/28/25.
//

import Foundation
import Combine

protocol AppDownloadInteractor {
    func startDownload(appId: String, duration: Double)
    func pauseDownload(appId: String)
    func resumeDownload(appId: String, duration: Double)
    func completeDownload(appId: String)
    func getDownloadState(for appId: String) -> AppState.DownloadsState.AppDownload?
    func restoreAllDownloadStates()
    func getCompletedAppIds() -> [String]
    func removeDownload(appId: String)
    
    func saveAppInfo(appId: String, appName: String, iconUrl: String)
    func getInstalledAppInfo(appId: String) -> AppState.DownloadsState.InstalledAppInfo?
    func getAllInstalledAppInfos() -> [AppState.DownloadsState.InstalledAppInfo]
    func checkPreviouslyDownloaded(appId: String) -> Bool
}

class AppDownloadInteractorImpl: AppDownloadInteractor {
    private let appState: Store<AppState>
    private let downloadRepository: DownloadRepository
    private var progressCancellables: [String: AnyCancellable] = [:]
    
    init(appState: Store<AppState>, downloadRepository: DownloadRepository) {
        self.appState = appState
        self.downloadRepository = downloadRepository
    }
    
    func startDownload(appId: String, duration: Double = 30.0) {
        appState.bulkUpdate { state in
            state.downloads.startDownload(for: appId)
        }
        saveCurrentDownloadState(for: appId)
        monitorProgress(for: appId, duration: duration)
    }
    
    func pauseDownload(appId: String) {
        appState.bulkUpdate { state in
            state.downloads.pauseDownload(for: appId)
        }
        progressCancellables[appId]?.cancel()
        progressCancellables.removeValue(forKey: appId)
        
        saveCurrentDownloadState(for: appId)
    }
    
    func resumeDownload(appId: String, duration: Double = 30.0) {
        appState.bulkUpdate { state in
            state.downloads.resumeDownload(for: appId)
        }
        
        saveCurrentDownloadState(for: appId)
        monitorProgress(for: appId, duration: duration)
    }
    
    func completeDownload(appId: String) {
        appState.bulkUpdate { state in
            state.downloads.completeDownload(for: appId)
        }
        
        progressCancellables[appId]?.cancel()
        progressCancellables.removeValue(forKey: appId)
        
        saveCurrentDownloadState(for: appId)
        
        downloadRepository.markAsPreviouslyDownloaded(appId: appId)
    }
    
    func getDownloadState(for appId: String) -> AppState.DownloadsState.AppDownload? {
        return appState.value.downloads.appDownloads[appId]
    }
    
    func restoreAllDownloadStates() {
        let downloadIds = downloadRepository.getAllSavedDownloadIds()
        
        for appId in downloadIds {
            if let savedState = downloadRepository.loadDownloadState(appId: appId) {
                appState.bulkUpdate { state in
                    state.downloads.appDownloads[appId] = savedState
                }
                if savedState.state == .downloading {
                    monitorProgress(for: appId, duration: 30.0)
                }
            }
        }
        let appInfos = downloadRepository.getAllInstalledAppInfos()
        
        for appInfo in appInfos {
            appState.bulkUpdate { state in
                state.downloads.installedApps[appInfo.appId] = appInfo
            }
        }
    }
    
    func getCompletedAppIds() -> [String] {
        let downloadStates = appState.value.downloads.appDownloads
        let completedAppIds = downloadStates
            .filter { $0.value.state == .completed }
            .map { $0.key }
        return completedAppIds
    }
    
    func removeDownload(appId: String) {
        downloadRepository.markAsPreviouslyDownloaded(appId: appId)
        
        appState.bulkUpdate { state in
            state.downloads.appDownloads.removeValue(forKey: appId)
            state.downloads.installedApps.removeValue(forKey: appId)
        }
        
        progressCancellables[appId]?.cancel()
        progressCancellables.removeValue(forKey: appId)

        downloadRepository.removeDownloadState(appId: appId)
        downloadRepository.removeInstalledAppInfo(appId: appId)
    }
    
    func saveAppInfo(appId: String, appName: String, iconUrl: String) {
        let appInfo = AppState.DownloadsState.InstalledAppInfo(
            appId: appId,
            appName: appName,
            iconUrl: iconUrl,
            installedDate: Date()
        )
        
        appState.bulkUpdate { state in
            state.downloads.installedApps[appId] = appInfo
        }
        
        downloadRepository.saveInstalledAppInfo(appInfo: appInfo)
    }
    
    func getInstalledAppInfo(appId: String) -> AppState.DownloadsState.InstalledAppInfo? {
        return appState.value.downloads.installedApps[appId] ?? downloadRepository.loadInstalledAppInfo(appId: appId)
    }
    
    func getAllInstalledAppInfos() -> [AppState.DownloadsState.InstalledAppInfo] {
        let installedApps = appState.value.downloads.installedApps
        return Array(installedApps.values)
    }
    
    func checkPreviouslyDownloaded(appId: String) -> Bool {
        return downloadRepository.wasPreviouslyDownloaded(appId: appId)
    }
    
    
    
    private func monitorProgress(for appId: String, duration: Double) {
        progressCancellables[appId]?.cancel()
        
        let cancellable = downloadRepository.monitorDownloadProgress(appId: appId, duration: duration)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                guard let self = self else { return }
                
                self.appState.bulkUpdate { state in
                    state.downloads.updateProgress(for: appId, progress: progress)
                }
                
                if progress >= 1.0 {
                    self.saveCurrentDownloadState(for: appId)
                    self.progressCancellables[appId]?.cancel()
                    self.progressCancellables.removeValue(forKey: appId)
                }
            }
        
        progressCancellables[appId] = cancellable
    }
    private func saveCurrentDownloadState(for appId: String) {
        if let currentState = getDownloadState(for: appId) {
            downloadRepository.saveDownloadState(appId: appId, state: currentState)
        }
    }
}
