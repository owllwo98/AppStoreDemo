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
    
    private static let sharedAppState = Store<AppState>(AppState())
    
    static let `default` = {
        let appState = sharedAppState
        let downloadRepository = DownloadRepositoryImpl()
        
        return Self(
            appState: appState,
            interactors: .init(
                itunesSearchInteractor: ItunesSearchInteractorImpl(
                    appState: appState,
                    itunesSearchRepository: ItunesSearchRepositoryImpl()
                ),
                networkInteractor: AppNetworkInteractorImpl(),
                downloadInteractor: AppDownloadInteractorImpl(
                    appState: appState,
                    downloadRepository: downloadRepository
                )
            ),
            services: .init(networkService: NetworkStatusServiceImpl()),
            cancelBag: CancelBag()
        )
    }()
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


extension DIContainer {
    struct Interactors {
        let itunesSearchInteractor: ItunesSearchInteractor
        let networkInteractor: AppNetworkInteractor
        let downloadInteractor: AppDownloadInteractor

        init(itunesSearchInteractor: ItunesSearchInteractor,
             networkInteractor: AppNetworkInteractor = AppNetworkInteractorImpl(),
             downloadInteractor: AppDownloadInteractor) {
            self.itunesSearchInteractor = itunesSearchInteractor
            self.networkInteractor = networkInteractor
            self.downloadInteractor = downloadInteractor
        }
    }
}
