//
//  DownloadRepository.swift
//  AppStoreDemo
//
//  Created by 변정훈 on 4/28/25.
//

import Foundation
import Combine

protocol DownloadRepository {
    func monitorDownloadProgress(appId: String, duration: Double) -> AnyPublisher<Double, Never>
    func saveDownloadState(appId: String, state: AppState.DownloadsState.AppDownload)
    func loadDownloadState(appId: String) -> AppState.DownloadsState.AppDownload?
    func getAllSavedDownloadIds() -> [String]
    func removeDownloadState(appId: String)
    
    func saveInstalledAppInfo(appInfo: AppState.DownloadsState.InstalledAppInfo)
    func loadInstalledAppInfo(appId: String) -> AppState.DownloadsState.InstalledAppInfo?
    func getAllInstalledAppInfos() -> [AppState.DownloadsState.InstalledAppInfo]
    func removeInstalledAppInfo(appId: String)
    
    func wasPreviouslyDownloaded(appId: String) -> Bool
    func markAsPreviouslyDownloaded(appId: String)
}

class DownloadRepositoryImpl: DownloadRepository {
    private let userDefaults = UserDefaults.standard
    private var progressTimers: [String: Timer] = [:]
    private var progressSubjects: [String: PassthroughSubject<Double, Never>] = [:]
    private let previousDownloadsKey = "previouslyDownloadedApps"

    
    private func stateKey(for appId: String) -> String {
        return "downloadState_\(appId)"
    }
    
    private func startTimeKey(for appId: String) -> String {
        return "startTime_\(appId)"
    }
    
    private func pauseTimeKey(for appId: String) -> String {
        return "pauseTime_\(appId)"
    }
    
    private func progressKey(for appId: String) -> String {
        return "downloadProgress_\(appId)"
    }
    
    private func appInfoKey(for appId: String) -> String {
        return "installedAppInfo_\(appId)"
    }
    
    func monitorDownloadProgress(appId: String, duration: Double) -> AnyPublisher<Double, Never> {
        progressTimers[appId]?.invalidate()
        
        let subject = progressSubjects[appId] ?? PassthroughSubject<Double, Never>()
        progressSubjects[appId] = subject
        
        let savedState = loadDownloadState(appId: appId)
        let startTime = savedState?.startTime ?? Date()
        let initialProgress = savedState?.progress ?? 0.0
        
        if savedState?.state == .paused {
            return subject.eraseToAnyPublisher()
        }
        
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            let elapsedTime = Date().timeIntervalSince(startTime)
            let progress = min(elapsedTime / duration, 1.0)
            
            subject.send(progress)
            
            if progress >= 1.0 {
                self?.progressTimers[appId]?.invalidate()
                self?.progressTimers.removeValue(forKey: appId)
            }
        }
        
        progressTimers[appId] = timer
        
        subject.send(initialProgress)
        
        return subject.eraseToAnyPublisher()
    }
    
    func saveDownloadState(appId: String, state: AppState.DownloadsState.AppDownload) {
        userDefaults.set(state.state.rawValue, forKey: stateKey(for: appId))
        
        if let startTime = state.startTime {
            userDefaults.set(startTime.timeIntervalSince1970, forKey: startTimeKey(for: appId))
        } else {
            userDefaults.removeObject(forKey: startTimeKey(for: appId))
        }
        
        if let pauseTime = state.pauseTime {
            userDefaults.set(pauseTime.timeIntervalSince1970, forKey: pauseTimeKey(for: appId))
        } else {
            userDefaults.removeObject(forKey: pauseTimeKey(for: appId))
        }
        
        userDefaults.set(state.progress, forKey: progressKey(for: appId))
    }
    
    func loadDownloadState(appId: String) -> AppState.DownloadsState.AppDownload? {
        guard let stateString = userDefaults.string(forKey: stateKey(for: appId)),
              let downloadState = AppState.DownloadsState.AppDownload.DownloadState(rawValue: stateString) else {
            return nil
        }
        
        var appDownload = AppState.DownloadsState.AppDownload()
        appDownload.state = downloadState
        
        if let startTimestamp = userDefaults.object(forKey: startTimeKey(for: appId)) as? Double {
            appDownload.startTime = Date(timeIntervalSince1970: startTimestamp)
        }
        
        if let pauseTimestamp = userDefaults.object(forKey: pauseTimeKey(for: appId)) as? Double {
            appDownload.pauseTime = Date(timeIntervalSince1970: pauseTimestamp)
        }
        
        appDownload.progress = userDefaults.double(forKey: progressKey(for: appId))
        
        return appDownload
    }
    
    func getAllSavedDownloadIds() -> [String] {
        let allKeys = userDefaults.dictionaryRepresentation().keys
        let downloadStateKeys = allKeys.filter { $0.hasPrefix("downloadState_") }
        return downloadStateKeys.map { String($0.dropFirst("downloadState_".count)) }
    }
    
    func removeDownloadState(appId: String) {
        progressTimers[appId]?.invalidate()
        progressTimers.removeValue(forKey: appId)
        
        progressSubjects.removeValue(forKey: appId)
        
        userDefaults.removeObject(forKey: stateKey(for: appId))
        userDefaults.removeObject(forKey: startTimeKey(for: appId))
        userDefaults.removeObject(forKey: pauseTimeKey(for: appId))
        userDefaults.removeObject(forKey: progressKey(for: appId))
    }
    
    func saveInstalledAppInfo(appInfo: AppState.DownloadsState.InstalledAppInfo) {
        if let encoded = try? JSONEncoder().encode(appInfo) {
            userDefaults.set(encoded, forKey: appInfoKey(for: appInfo.appId))
        }
    }
    
    func loadInstalledAppInfo(appId: String) -> AppState.DownloadsState.InstalledAppInfo? {
        guard let data = userDefaults.data(forKey: appInfoKey(for: appId)) else {
            return nil
        }
        
        return try? JSONDecoder().decode(AppState.DownloadsState.InstalledAppInfo.self, from: data)
    }
    
    func getAllInstalledAppInfos() -> [AppState.DownloadsState.InstalledAppInfo] {
        let allKeys = userDefaults.dictionaryRepresentation().keys
        let appInfoKeys = allKeys.filter { $0.hasPrefix("installedAppInfo_") }
        let appIds = appInfoKeys.map { String($0.dropFirst("installedAppInfo_".count)) }
        
        return appIds.compactMap { loadInstalledAppInfo(appId: $0) }
    }
    
    func removeInstalledAppInfo(appId: String) {
        userDefaults.removeObject(forKey: appInfoKey(for: appId))
    }
    
    func wasPreviouslyDownloaded(appId: String) -> Bool {
        let previousDownloads = userDefaults.array(forKey: previousDownloadsKey) as? [String] ?? []
        return previousDownloads.contains(appId)
    }

    func markAsPreviouslyDownloaded(appId: String) {
        var previousDownloads = userDefaults.array(forKey: previousDownloadsKey) as? [String] ?? []
        if !previousDownloads.contains(appId) {
            previousDownloads.append(appId)
            userDefaults.set(previousDownloads, forKey: previousDownloadsKey)
        }
    }
}
