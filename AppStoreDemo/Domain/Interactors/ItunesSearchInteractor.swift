//
//  ItunesSearchInteractor.swift
//  AppStoreDemo
//
//  Created by 변정훈 on 4/27/25.
//

import Foundation
import Combine

protocol ItunesSearchInteractor {
    func searchApps(query: String, results: LoadableSubject<[ItunesSearchResponseDTO]>)
}

final class ItunesSearchInteractorImpl: ItunesSearchInteractor {
    private let appState: Store<AppState>
    private let cancelBag = CancelBag()
    private let itunesSearchRepository: ItunesSearchRepository
    
    init(appState: Store<AppState>, itunesSearchRepository: ItunesSearchRepository) {
        self.appState = appState
        self.itunesSearchRepository = itunesSearchRepository
    }
    
    func searchApps(query: String, results: LoadableSubject<[ItunesSearchResponseDTO]>) {
        itunesSearchRepository
            .searchApps(query: query)
            .receive(on: DispatchQueue.main)
            .sinkToLoadable(results, cancelBag: cancelBag)
    }
}
