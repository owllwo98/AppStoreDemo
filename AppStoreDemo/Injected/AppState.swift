//
//  AppState.swift
//  AppStoreDemo
//
//  Created by 변정훈 on 4/24/25.
//

import SwiftUI
import Combine
import Network // 네트워크 상태를 모니터링하기 위해 Network 프레임워크 사용

// 앱 상태를 정의하는 구조체
struct AppState: Equatable {
    var network = NetworkStatus()
    
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
}

// MARK: - AppStore
final class AppStore: ObservableObject {
    let container: DIContainer
    
    init(container: DIContainer = .defaultValue) {
        self.container = container
        setup()
    }
    
    private func setup() {
        // 네트워크 상태 바인딩
        container.interactors.networkInteractor.bindNetworkStatus(
            to: container.appState,
            from: container.services.networkService,
            cancelBag: container.cancelBag
        )
        
        // 네트워크 모니터링 시작
        container.services.networkService.startMonitoring()
        
        // SwiftUI와 Combine 연동
        container.appState
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: container.cancelBag) // CancelBag 사용
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
            .store(in: cancelBag) // 수정: AppStore. -> cancelBag
    }
}

final class CancelBag {
    fileprivate(set) var subscriptions = Set<AnyCancellable>()
    private let equalToAny: Bool
    
    init(equalToAny: Bool = false) {
        self.equalToAny = equalToAny
    }
    
    func cancel() {
        subscriptions.removeAll()
    }
    
    func isEqual(to other: CancelBag) -> Bool {
        return other === self || other.equalToAny || self.equalToAny
    }
}

extension AnyCancellable {
    
    func store(in cancelBag: CancelBag) {
        cancelBag.subscriptions.insert(self)
    }
}





typealias LoadableSubject<Value> = Binding<Loadable<Value>>

enum Loadable<T> {
    case notRequest
    case loading
    case success(T)
    case error(NetworkError)

    var value: T? {
        switch self {
        case let .success(value): return value
        default: return nil
        }
    }
    
    mutating func setLoading() {
        self = .loading
    }
    
    mutating func setSuccess(value: T) {
        self = .success(value)
    }
    
    mutating func setError(error: NetworkError) {
        self = .error(error)
    }
}

extension Loadable {
    // 로딩 상태 확인용
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    // 에러 상태 확인용
    var isError: Bool {
        if case .error = self { return true }
        return false
    }
}

/// Loadable 타입 소거 구조체
/// 각 제네릭 타입에 대응하기 위해 타입 소거하고, 상타값만 전달하는 방식으로 지정
/// - NetworkStateView에서는 값 상관없이 해당 상태만 관측하면 되기에 해당 방식 이용
/// - 각 제네릭 타입에 대응하기 위한 수단
struct AnyLoadable {
    private let _isLoading: () -> Bool
    private let _isError: () -> Bool
    private let _setNotRequest: () -> Void

    init<T>(_ loadable: Binding<Loadable<T>>) {
        _isLoading = { loadable.wrappedValue.isLoading }
        _isError = { loadable.wrappedValue.isError }
        _setNotRequest = { loadable.wrappedValue = .notRequest }
    }

    var isLoading: Bool { _isLoading() }
    var isError: Bool { _isError() }
    func setNotRequest() { _setNotRequest() }
}
