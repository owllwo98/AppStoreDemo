//
//  ItunesSearchResponseDTO.swift
//  AppStoreDemo
//
//  Created by 변정훈 on 4/27/25.
//

import Foundation

struct ItunesSearchResponseDTO: Decodable, Encodable {
    let artistId: Int
    let artistName: String
    let artistViewUrl: String
    let artworkUrl60: String
    let artworkUrl100: String
    let artworkUrl512: String
    let screenshotUrls: [String]
    let bundleId: String
    let trackId: Int
    let minimumOsVersion: String
    let sellerName: String
    let trackName: String
    let contentAdvisoryRating: String
    let trackViewUrl: String
    let description: String
    let price: Double
    let formattedPrice: String
    let version: String
    let releaseNotes: String
    let primaryGenreName: String
    let genres: [String]
    let averageUserRating: Double
    let userRatingCount: Int

    private enum CodingKeys: String, CodingKey {
        case artistId
        case artistName
        case artistViewUrl
        case artworkUrl60
        case artworkUrl100
        case artworkUrl512
        case screenshotUrls
        case bundleId
        case trackId
        case minimumOsVersion
        case sellerName
        case trackName
        case contentAdvisoryRating
        case trackViewUrl
        case description
        case price
        case formattedPrice
        case version
        case releaseNotes
        case primaryGenreName
        case genres
        case averageUserRating
        case userRatingCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        artistId = try container.decode(Int.self, forKey: .artistId)
        artistName = try container.decode(String.self, forKey: .artistName)
        artistViewUrl = try container.decode(String.self, forKey: .artistViewUrl)
        artworkUrl60 = try container.decode(String.self, forKey: .artworkUrl60)
        artworkUrl100 = try container.decode(String.self, forKey: .artworkUrl100)
        artworkUrl512 = try container.decode(String.self, forKey: .artworkUrl512)
        screenshotUrls = try container.decode([String].self, forKey: .screenshotUrls)
        bundleId = try container.decode(String.self, forKey: .bundleId)
        trackId = try container.decode(Int.self, forKey: .trackId)
        minimumOsVersion = try container.decode(String.self, forKey: .minimumOsVersion)
        sellerName = try container.decode(String.self, forKey: .sellerName)
        trackName = try container.decode(String.self, forKey: .trackName)
        contentAdvisoryRating = try container.decode(String.self, forKey: .contentAdvisoryRating)
        trackViewUrl = try container.decode(String.self, forKey: .trackViewUrl)
        description = try container.decode(String.self, forKey: .description)
        price = try container.decode(Double.self, forKey: .price)
        formattedPrice = try container.decode(String.self, forKey: .formattedPrice)
        version = try container.decode(String.self, forKey: .version)
        primaryGenreName = try container.decode(String.self, forKey: .primaryGenreName)
        genres = try container.decode([String].self, forKey: .genres)

        releaseNotes = (try? container.decodeIfPresent(String.self, forKey: .releaseNotes)) ?? "새로운 소식이 없습니다."
        averageUserRating = (try? container.decodeIfPresent(Double.self, forKey: .averageUserRating)) ?? 0.0
        userRatingCount = (try? container.decodeIfPresent(Int.self, forKey: .userRatingCount)) ?? 0
    }
}

