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

fileprivate let itemsKey = "items"
fileprivate let syncLimitKey = "limit_sync"

struct CardIdsModel: Decodable {
    let ids: [Int]
    let syncLimit: Int
    
    init?(json: JSON) {
        guard let items:[Int] = itemsKey <~~ json,
            let limit: Int = syncLimitKey <~~ json  else {
            return nil
        }
        ids = items
        syncLimit = limit
    }
    
    init(ids: [Int]) {
        self.ids = ids
        self.syncLimit = defaultSyncLimit
    }
    
    static func nullObject() -> CardIdsModel {
        return CardIdsModel(json: [itemsKey:[], syncLimitKey:defaultSyncLimit])!
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
    
    init(reviewType: ReviewType, learnedOnly: Bool = false) {
        self.reviewType = reviewType
        
        var type = reviewType.querystringParam
        if case .failed = reviewType,
            learnedOnly {
            type = "learned"
        }
        qsParams = [ "mode": "srs",
                     "type": type ]
        
        var ids = ""
        switch reviewType {
        case .expired:
            ids = GuestData.dueIds.description
        case .failed:
            ids = GuestData.failedIds.description
        default:
            ids = "[]"
        }
        self.guestResult = "{\"stat\":\"ok\",\"card_count\":10,\"items\":\(ids),\"limit_fetch\":10,\"limit_sync\":50,\"dbg_generation_time\":\"515\"}"
    }
    
    let guestResult: String?
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
    
    let guestResult: String? = ""
}
