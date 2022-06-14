//
//  File.swift
//
//
//  Created by Vitali Kurlovich on 14.06.22.
//

import Foundation

public
extension DukascopyHistory {
    typealias Provider = DukascopyHistoryProvider

    func provider() -> Provider {
        .init(self)
    }
}
