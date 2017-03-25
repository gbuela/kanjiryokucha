//
//  GetLearnedIds.swift
//  KanjiRyokucha
//
//  Created by German Buela on 3/24/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import Foundation
import Gloss

struct GetLearnedIdsRequest: KoohiiRequest {
    typealias ModelType = CardIdsModel
    let apiMethod = "srs/learned"
    let useEndpoint = true
    let sendApiKey = true
    let method = RequestMethod.get
    let contentType = ContentType.form
}
