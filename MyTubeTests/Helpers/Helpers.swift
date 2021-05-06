//
//  Helpers.swift
//  MyTubeTests
//
//  Created by Jiri Urbasek on 4/18/21.
//

import Foundation

struct MockError: Error, Equatable {
    var message: String
}

extension String {
    var url: URL { URL(string: self)! }
    var request: URLRequest { .init(url: url) }
}
