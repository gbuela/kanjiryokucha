//
//  Log.swift
//  KanjiRyokucha
//
//  Created by German Buela on 4/14/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import Foundation

func log(_ string: String) {
    #if DEBUG
        print(string)
    #endif
}
