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
        // 앱별 다운로드 상태를 저장하는 딕셔너리
        var appDownloads: [String: AppDownload] = [:]
        
        // 설치된 앱 정보를 저장하는 딕셔너리
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
        
        // 설치된 앱 정보를 저장하는 구조체
        struct InstalledAppInfo: Equatable, Codable {
            var appId: String          // 앱 ID (번들 ID)
            var appName: String        // 앱 이름
            var iconUrl: String        // 앱 아이콘 URL
            var installedDate: Date    // 설치 날짜
        }
        
        // 다운로드 시작
        mutating func startDownload(for appId: String) {
            var appDownload = appDownloads[appId] ?? AppDownload()
            appDownload.state = .downloading
            appDownload.startTime = Date()
            appDownload.progress = 0.0
            appDownload.pauseTime = nil
            appDownloads[appId] = appDownload
        }
        
        // 다운로드 일시정지
        mutating func pauseDownload(for appId: String) {
            guard var appDownload = appDownloads[appId] else { return }
            appDownload.state = .paused
            appDownload.pauseTime = Date()
            appDownloads[appId] = appDownload
        }
        
        // 다운로드 재개
        mutating func resumeDownload(for appId: String) {
            guard var appDownload = appDownloads[appId],
                  let pause = appDownload.pauseTime,
                  let start = appDownload.startTime else { return }
            
            // 일시정지된 시간을 고려하여 시작 시간 조정
            let pausedDuration = pause.timeIntervalSince(start)
            appDownload.startTime = Date().addingTimeInterval(-pausedDuration)
            appDownload.state = .downloading
            appDownload.pauseTime = nil
            appDownloads[appId] = appDownload
        }
        
        // 진행 상태 업데이트
        mutating func updateProgress(for appId: String, progress: Double) {
            guard var appDownload = appDownloads[appId] else { return }
            appDownload.progress = progress
            
            // 다운로드 완료 처리
            if progress >= 1.0 {
                appDownload.state = .completed
                appDownload.progress = 1.0
                appDownload.startTime = nil
                appDownload.pauseTime = nil
            }
            
            appDownloads[appId] = appDownload
        }
        
        // 명시적으로 다운로드 완료 처리
        mutating func completeDownload(for appId: String) {
            guard var appDownload = appDownloads[appId] else { return }
            appDownload.state = .completed
            appDownload.progress = 1.0
            appDownload.startTime = nil
            appDownload.pauseTime = nil
            appDownloads[appId] = appDownload
        }
        
        // 설치된 앱 정보 저장
        mutating func saveInstalledAppInfo(appInfo: InstalledAppInfo) {
            installedApps[appInfo.appId] = appInfo
        }
        
        // 설치된 앱 정보 삭제
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
        // 네트워크 상태 바인딩
        container.interactors.networkInteractor.bindNetworkStatus(
            to: container.appState,
            from: container.services.networkService,
            cancelBag: container.cancelBag
        )
        
        // 네트워크 모니터링 시작
        container.services.networkService.startMonitoring()
        
        // 다운로드 상태 복원
        container.interactors.downloadInteractor.restoreAllDownloadStates()
        
        // SwiftUI와 Combine 연동
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

// 네트워크 서비스 프로토콜
protocol NetworkStatusService {
    var networkStatus: AnyPublisher<AppState.NetworkStatus, Never> { get }
    func startMonitoring()
}

// 네트워크 서비스 구현
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

// 네트워크 인터랙터 프로토콜
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
