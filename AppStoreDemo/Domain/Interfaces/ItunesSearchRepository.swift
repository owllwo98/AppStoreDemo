//
//  ItunesSearchRepository.swift
//  AppStoreDemo
//
//  Created by 변정훈 on 4/27/25.
//

import Foundation
import Combine

protocol ItunesSearchRepository {
    func searchApps(query: String) -> AnyPublisher<[ItunesSearchResponseDTO], NetworkError>
}
