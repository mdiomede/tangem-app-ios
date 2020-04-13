//
//  Wallet.swift
//  blockchainSdk
//
//  Created by Alexander Osokin on 04.12.2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public protocol Wallet: class {
    var blockchain: Blockchain {get}
    var address: String {get}
    var exploreUrl: String? {get}
    var shareUrl: String? {get}
    var allowExtract: Bool {get}
    var allowLoad: Bool {get}
    var token: Token? {get}
}
