//
//  DIContainer.swift
//  AppStoreDemo
//
//  Created by 변정훈 on 4/24/25.
//

import SwiftUI
import Combine

struct DIContainer: EnvironmentKey {
    let appState: Store<AppState>
    let interactors: Interactors
    let services: Services
    let cancelBag: CancelBag 
    
    init(appState: Store<AppState>,
         interactors: Interactors,
         services: Services,
         cancelBag: CancelBag = CancelBag()) {
        self.appState = appState
        self.interactors = interactors
        self.services = services
        self.cancelBag = cancelBag
    }
    
    static var defaultValue: Self { Self.default }
    
    static let `default` = Self(
        appState: .init(AppState()),
        interactors: .default,
        services: .init(),
        cancelBag: CancelBag()
    )
}

extension EnvironmentValues {
    var injected: DIContainer {
        get { self[DIContainer.self] }
        set { self[DIContainer.self] = newValue }
    }
}
extension View {
    func inject(_ container: DIContainer) -> some View {
        environment(\.injected, container)
    }
}

typealias Store<State> = CurrentValueSubject<State, Never>

extension Store {
    
    subscript<T>(keyPath: WritableKeyPath<Output, T>) -> T where T: Equatable {
        get { value[keyPath: keyPath] }
        set {
            var value = self.value
            if value[keyPath: keyPath] != newValue {
                value[keyPath: keyPath] = newValue
                self.value = value
            }
        }
    }
    
    func bulkUpdate(_ update: (inout Output) -> Void) {
        var value = self.value
        update(&value)
        self.value = value
    }
    
    func updates<Value>(for keyPath: KeyPath<Output, Value>) ->
    AnyPublisher<Value, Failure> where Value: Equatable {
        return map(keyPath).removeDuplicates().eraseToAnyPublisher()
    }
}

extension Binding where Value: Equatable {
    func dispatched<State>(to state: Store<State>,
                           _ keyPath: WritableKeyPath<State, Value>) -> Self {
        return onSet { state[keyPath] = $0 }
    }
}

extension Binding where Value: Equatable {
    typealias ValueClosure = (Value) -> Void
    
    func onSet(_ perform: @escaping ValueClosure) -> Self {
        return .init(get: { () -> Value in
            self.wrappedValue
        }, set: { value in
            if self.wrappedValue != value {
                self.wrappedValue = value
            }
            perform(value)
        })
    }
}


extension DIContainer {
    struct Interactors {
        let itunesSearchInteractor: ItunesSearchInteractor
        let networkInteractor: AppNetworkInteractor // 수정

        init(itunesSearchInteractor: ItunesSearchInteractor, networkInteractor: AppNetworkInteractor = AppNetworkInteractorImpl()) {
            self.itunesSearchInteractor = itunesSearchInteractor
            self.networkInteractor = networkInteractor
        }

        static let `default` = Self(
            itunesSearchInteractor: ItunesSearchInteractorImpl(
                appState: Store<AppState>(AppState()),
                itunesSearchRepository: ItunesSearchRepositoryImpl()
            )
        )
    }
}
