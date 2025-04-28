//
//  ItunesSearchRepository.swift
//  AppStoreDemo
//
//  Created by 변정훈 on 4/27/25.
//

import Foundation
import Combine

final class ItunesSearchRepositoryImpl: ItunesSearchRepository {
    
    func searchApps(query: String) -> AnyPublisher<[ItunesSearchResponseDTO], NetworkError> {
        return Future<[ItunesSearchResponseDTO], NetworkError> { promise in
            Task {
                do {
                    let endpoint = ItunesSearchEndpoint.search(query: query)
                    let response: ITunesApiResponse<ItunesSearchResponseDTO> = try await NetworkService.shared.request(endpoint: endpoint)
                    promise(.success(response.results))
                } catch let error as NetworkError {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
