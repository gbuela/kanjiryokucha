//
//  KanjiDetailsRequest.swift
//  KanjiRyokucha
//
//  Created by German Buela on 2/12/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import Foundation
import Gloss

struct KanjiDetailsModel: Gloss.Decodable {
    let strokeCount: Int
    let meaning: String
    let onyomi: String
    let kunyomi: String
    let videoUrl: String?
    
    init?(json: JSON) {
        guard let kanjiObject: JSON = "kanji" <~~ json,
            let strokesObject: JSON = "strokes" <~~ kanjiObject,
            let meaningObject: JSON = "meaning" <~~ kanjiObject,
            let englishMeaning: String = "english" <~~ meaningObject,
            let count: Int = "count" <~~ strokesObject else {
                return nil
        }
        self.strokeCount = count
        self.meaning = englishMeaning
        
        if let onyomiObject: JSON = "onyomi" <~~ kanjiObject,
            let onyomi: String = "katakana" <~~ onyomiObject {
            self.onyomi = onyomi
        } else {
            self.onyomi = ""
        }
        
        if let kunyomiObject: JSON = "kunyomi" <~~ kanjiObject,
            let kunyomi: String = "hiragana" <~~ kunyomiObject {
            self.kunyomi = kunyomi
        } else {
            self.kunyomi = ""
        }
        
        if let videoObject: JSON = "video" <~~ kanjiObject,
            let mp4Url: String = "mp4" <~~ videoObject {
            self.videoUrl = mp4Url
        } else {
            self.videoUrl = nil
        }
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
