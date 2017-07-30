//
//  StartRequest.swift
//  KanjiRyokucha
//
//  Created by German Buela on 12/9/16.
//  Copyright © 2016 German Buela. All rights reserved.
//

import Foundation

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
    
    init(ids: [Int]) {
        self.ids = ids
        self.syncLimit = defaultSyncLimit
    }
    
    static func nullObject() -> CardIdsModel {
        return CardIdsModel(ids: [])
    }
    
    enum CodingKeys: String, CodingKey {
        case ids = "items"
        case syncLimit = "limit_sync"
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
    }
    
    var guestResult: String? {
        var ids = ""
        switch reviewType {
        case .expired:
            ids = GuestData.dueIds.description
        case .failed:
            ids = GuestData.reviewableFailedIds.description
        default:
            ids = "[]"
        }
        
        return "{\"stat\":\"ok\",\"card_count\":10,\"items\":\(ids),\"limit_fetch\":10,\"limit_sync\":50,\"dbg_generation_time\":\"515\"}"
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
    
    let guestResult: String? = ""
}
