//
//  ItunesSearchEndpoint.swift
//  AppStoreDemo
//
//  Created by 변정훈 on 4/27/25.
//

import Foundation

enum ItunesSearchEndpoint: EndpointProtocol {
    case search(query: String)
}

extension ItunesSearchEndpoint {
    var baseURL: URL? {
        return URL(string: "https://itunes.apple.com")
    }
    
    var path: String {
        switch self {
        case .search:
            return "search"
        }
    }
    
    var method: NetworkMethod {
        switch self {
        case .search:
            return .get
        }
    }
    
    var parameters: [URLQueryItem]? {
        switch self {
        case let .search(query):
            return [
                URLQueryItem(name: "term", value: query),
                URLQueryItem(name: "country", value: "kr"),
                URLQueryItem(name: "entity", value: "software")
            ]
        }
    }
    
    var headers: [String: String]? {
        return ["Content-Type": "application/json"]
    }
    
    var body: Data? {
        return nil
    }
}
