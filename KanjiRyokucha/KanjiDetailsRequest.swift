//
//  KanjiDetailsRequest.swift
//  KanjiRyokucha
//
//  Created by German Buela on 2/12/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import Foundation

struct KanjiDetailsModel: Decodable {
    let strokeCount: Int
    let meaning: String
    let onyomi: String
    let kunyomi: String
    let videoUrl: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kanjiContainer = try container.nestedContainer(keyedBy: KanjiCodingKeys.self, forKey: .kanji)
        let strokesContainer = try kanjiContainer.nestedContainer(
            keyedBy: SrokesCodingKeys.self, forKey: .strokes)
        let meaningContainer = try kanjiContainer.nestedContainer(keyedBy: MeaningCodingKeys.self, forKey: .meaning)
        
        do {
            let onyomiContainer = try kanjiContainer.nestedContainer(keyedBy: OnyomiCodingKeys.self, forKey: .onyomi)
            self.onyomi = try onyomiContainer.decodeIfPresent(String.self, forKey: .katakana) ?? ""
        } catch {
            self.onyomi = ""
        }
        
        do {
            let kunyomiContainer = try kanjiContainer.nestedContainer(keyedBy: KunyomiCodingKeys.self, forKey: .kunyomi)
            self.kunyomi = try kunyomiContainer.decodeIfPresent(String.self, forKey: .hiragana) ?? ""
        } catch {
            self.kunyomi = ""
        }
        
        self.strokeCount = try strokesContainer.decode(Int.self, forKey: .count)
        self.meaning = try meaningContainer.decode(String.self, forKey: .english)
        
        do {
            let videoContainer = try kanjiContainer.nestedContainer(keyedBy: VideoCodingKeys.self, forKey: .video)
            self.videoUrl = try videoContainer.decodeIfPresent(String.self, forKey: .mp4)
        } catch {
            self.videoUrl = nil
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case kanji
    }
    enum KanjiCodingKeys: String, CodingKey {
        case strokes
        case meaning
        case onyomi
        case kunyomi
        case video
    }
    enum SrokesCodingKeys: String, CodingKey {
        case count
    }
    enum MeaningCodingKeys: String, CodingKey {
        case english
    }
    enum OnyomiCodingKeys: String, CodingKey {
        case katakana
    }
    enum KunyomiCodingKeys: String, CodingKey {
        case hiragana
    }
    enum VideoCodingKeys: String, CodingKey {
        case mp4
    }
}

struct KanjiDetailsRequest: KanjialiveRequest {
    typealias ModelType = KanjiDetailsModel
    var apiMethod: String {
        return "kanji/" + kanji
    }
    let useEndpoint = true
    let sendApiKey = true
    let method = RequestMethod.get
    let contentType = ContentType.json
    let kanji: String
    
    init(kanji: String) {
        self.kanji = kanji
    }
}
