//
//  ITunesApiResponse.swift
//  AppStoreDemo
//
//  Created by 변정훈 on 4/27/25.
//

import Foundation

struct ITunesApiResponse<T: Decodable>: Decodable {
    let resultCount: Int
    let results: [T]
    
    enum CodingKeys: String, CodingKey {
        case resultCount
        case results
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        resultCount = try container.decode(Int.self, forKey: .resultCount)
        results = try container.decode([T].self, forKey: .results)
    }
}
