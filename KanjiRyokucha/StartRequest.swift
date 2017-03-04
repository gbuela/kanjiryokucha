//
//  StartRequest.swift
//  KanjiRyokucha
//
//  Created by German Buela on 12/9/16.
//  Copyright © 2016 German Buela. All rights reserved.
//

import Foundation
import Gloss

extension ReviewType {
    var querystringParam: String {
        switch self {
        case .expired:
            return "due"
        case .new:
            return "new"
        case .failed:
            return "failed"
        }
    }
}

internal let itemsKey = "items"

struct CardIdsModel: Decodable {
    let ids: [Int]
    
    init?(json: JSON) {
        guard let items:[Int] = itemsKey <~~ json else {
            return nil
        }
        ids = items
    }
    
    init(ids: [Int]) {
        self.ids = ids
    }
    
    static func nullObject() -> CardIdsModel {
        return CardIdsModel(json: [itemsKey:[]])!
    }
}

protocol StartRequest : KoohiiRequest {}

extension StartRequest {
    var apiMethod: String {
        return "review/start"
    }

    var useEndpoint: Bool {
        return true
    }
    
    var sendApiKey: Bool {
        return true
    }
    
    var method: RequestMethod {
        return .get
    }
    
    var contentType: ContentType {
        return .form
    }
}

struct SRSStartRequest: StartRequest {
    let reviewType: ReviewType
    let qsParams: ParamSet
    
    typealias ModelType = CardIdsModel

    var querystringParams: ParamSet {
        return qsParams
    }
    
    init(reviewType: ReviewType) {
        self.reviewType = reviewType
        qsParams = [ "mode": "srs",
                     "type": reviewType.querystringParam ]
    }
}

struct FreeReviewStartRequest: StartRequest {
    let qsParams: ParamSet
    
    typealias ModelType = CardIdsModel

    var querystringParams: ParamSet {
        return qsParams
    }
    
    init(fromIndex:Int, toIndex:Int, shuffle:Bool) {
        qsParams = [ "mode": "free",
                     "from": String(fromIndex),
                     "to": String(toIndex),
                     "shuffle": (shuffle ? "1" : "0") ]
    }
}
