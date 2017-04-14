//
//  ArrayExtensions.swift
//  KanjiRyokucha
//
//  Created by German Buela on 4/13/17.
//  Copyright © 2017 German Buela. All rights reserved.
//

import Foundation


extension Array where Element: Equatable {
    func removing(_ objects: [Element]) ->[Element] {
        var newArray = self
        objects.forEach {
            if let index = newArray.index(of: $0) {
                newArray.remove(at: index)
            }
        }
        return newArray
    }
}

extension Array {
    func chunks(ofSize chunkSize: Int) -> [[Element]] {
        let chunks = stride(from: 0, to: count, by: chunkSize).map {
            Array(self[$0..<Swift.min($0 + chunkSize, count)])
        }
        return chunks
    }
}

extension Array where Element : ReviewEntry {
    
    func count(answer: CardAnswer) -> Int {
        return self.filter { $0.rawAnswer == answer.rawValue }.count
    }
    
    var countSubmitted: Int {
        return self.filter { $0.submitted }.count
    }
    
    var countUnsubmitted: Int {
        return self.filter { !$0.submitted && $0.rawAnswer != CardAnswer.unanswered.rawValue }.count
    }
}
