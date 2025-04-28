//
//  AppState.swift
//  AppStoreDemo
//
//  Created by 변정훈 on 4/24/25.
//

import SwiftUI
import Combine
import Network

struct AppState: Equatable {
    var network = NetworkStatus()
    var downloads = DownloadsState()
    
    struct NetworkStatus: Equatable {
        var connection: Connection = .disconnected
        var lastChecked: Date = .now
        
        enum Connection: Equatable {
            case connected
            case disconnected
            case unstable
        }
        
        var statusDescription: String {
            switch connection {
            case .connected: return "Connected"
            case .disconnected: return "Disconnected"
            case .unstable: return "Unstable Connection"
            }
        }
    }
    
    struct DownloadsState: Equatable {
        
        var appDownloads: [String: AppDownload] = [:]
        
        var installedApps: [String: InstalledAppInfo] = [:]
        
        struct AppDownload: Equatable {
            var state: DownloadState = .idle
            var progress: Double = 0.0
            var startTime: Date?
            var pauseTime: Date?
            
            enum DownloadState: String, Equatable {
                case idle     
                case downloading
                case paused
                case completed
                case redownload
            }
        }
        
        struct InstalledAppInfo: Equatable, Codable {
            var appId: String
            var appName: String
            var iconUrl: String
            var installedDate: Date
        }
        
        mutating func startDownload(for appId: String) {
            var appDownload = appDownloads[appId] ?? AppDownload()
            appDownload.state = .downloading
            appDownload.startTime = Date()
            appDownload.progress = 0.0
            appDownload.pauseTime = nil
            appDownloads[appId] = appDownload
        }
        
        mutating func pauseDownload(for appId: String) {
            guard var appDownload = appDownloads[appId] else { return }
            appDownload.state = .paused
            appDownload.pauseTime = Date()
            appDownloads[appId] = appDownload
        }
        
        mutating func resumeDownload(for appId: String) {
            guard var appDownload = appDownloads[appId],
                  let pause = appDownload.pauseTime,
                  let start = appDownload.startTime else { return }
            
            let pausedDuration = pause.timeIntervalSince(start)
            appDownload.startTime = Date().addingTimeInterval(-pausedDuration)
            appDownload.state = .downloading
            appDownload.pauseTime = nil
            appDownloads[appId] = appDownload
        }
        
        mutating func updateProgress(for appId: String, progress: Double) {
            guard var appDownload = appDownloads[appId] else { return }
            appDownload.progress = progress
            
            if progress >= 1.0 {
                appDownload.state = .completed
                appDownload.progress = 1.0
                appDownload.startTime = nil
                appDownload.pauseTime = nil
            }
            
            appDownloads[appId] = appDownload
        }
        
        mutating func completeDownload(for appId: String) {
            guard var appDownload = appDownloads[appId] else { return }
            appDownload.state = .completed
            appDownload.progress = 1.0
            appDownload.startTime = nil
            appDownload.pauseTime = nil
            appDownloads[appId] = appDownload
        }
        
        mutating func saveInstalledAppInfo(appInfo: InstalledAppInfo) {
            installedApps[appInfo.appId] = appInfo
        }
        
        mutating func removeInstalledAppInfo(appId: String) {
            installedApps.removeValue(forKey: appId)
        }
    }
}

// MARK: - AppStore
final class AppStore: ObservableObject {
    let container: DIContainer
    
    init(container: DIContainer = .defaultValue) {
        self.container = container
        setup()
    }
}

extension AppStore {
    private func setup() {
        container.interactors.networkInteractor.bindNetworkStatus(
            to: container.appState,
            from: container.services.networkService,
            cancelBag: container.cancelBag
        )
        
        container.services.networkService.startMonitoring()
        
        container.interactors.downloadInteractor.restoreAllDownloadStates()
        
        container.appState
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: container.cancelBag)
    }
}

struct Services {
    let networkService: NetworkStatusService
    
    init(networkService: NetworkStatusService = NetworkStatusServiceImpl()) {
        self.networkService = networkService
    }
}

protocol NetworkStatusService {
    var networkStatus: AnyPublisher<AppState.NetworkStatus, Never> { get }
    func startMonitoring()
}

class NetworkStatusServiceImpl: NetworkStatusService {
    private let monitor = NWPathMonitor()
    private let subject = PassthroughSubject<AppState.NetworkStatus, Never>()
    
    var networkStatus: AnyPublisher<AppState.NetworkStatus, Never> {
        subject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            let status = AppState.NetworkStatus(
                connection: path.status == .satisfied ? .connected : .disconnected,
                lastChecked: .now
            )
            self?.subject.send(status)
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
}

struct Interactors {
    let networkInteractor: AppNetworkInteractor
    
    static let `default` = Interactors(networkInteractor: AppNetworkInteractorImpl())
}

protocol AppNetworkInteractor {
    func bindNetworkStatus(to store: Store<AppState>, from service: NetworkStatusService, cancelBag: CancelBag)
}

struct AppNetworkInteractorImpl: AppNetworkInteractor {
    func bindNetworkStatus(to store: Store<AppState>, from service: NetworkStatusService, cancelBag: CancelBag) {
        service.networkStatus
            .sink { status in
                store.bulkUpdate { state in
                    state.network = status
                }
            }
            .store(in: cancelBag)
    }
}
