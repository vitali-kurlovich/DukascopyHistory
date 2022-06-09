//
//  Created by Vitali Kurlovich on 31.05.22.
//

import AsyncHTTPClient
import Foundation
import NIO
import NIOHTTP1

extension HTTPMethod: Hashable {}

struct RequestKey: Hashable {
    struct Header: Hashable {
        let name: String
        let value: String
    }

    let method: HTTPMethod
    let url: URL
    let headers: Set<Header>
}

extension RequestKey {
    init(_ request: HTTPClient.Request) {
        method = request.method
        url = request.url

        let mapped = request.headers.map { (name: String, value: String) in
            Self.Header(name: name, value: value)
        }

        headers = Set(mapped)
    }
}
