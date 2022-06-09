//
//  Created by Vitali Kurlovich on 9.06.22.
//

import AsyncHTTPClient
import Foundation
import NIO

import DukascopyModel
import KeyValueCache

final class ClientCache {
    internal let cache: KeyValueCache<RequestKey, HTTPClient.Response>
    internal let groupsCache: OneValueCache<[Group]>

    init(_ eventLoopGroup: EventLoopGroup) {
        cache = .init(eventLoopGroupProvider: .shared(eventLoopGroup))
        groupsCache = .init(eventLoopGroupProvider: .shared(eventLoopGroup))

        cache.totalCostLimit = 2 * 1024 * 1024
    }

    func response(for request: HTTPClient.Request) -> EventLoopFuture<HTTPClient.Response?> {
        cache.value(forKey: .init(request))
    }

    func set(response: HTTPClient.Response, for request: HTTPClient.Request, expireDate: Date? = nil) {
        let cost = response.body?.storageCapacity ?? 1
        cache.setValue(response, forKey: .init(request), expireDate: expireDate, cost: cost)
    }

    func groups() -> EventLoopFuture<[Group]?> {
        groupsCache.value()
    }

    func set(groups: [Group], expireDate: Date?) {
        groupsCache.setValue(groups, expireDate: expireDate)
    }
}
