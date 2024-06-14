//
//  CryptoFiatAmount.swift
//  Tangem
//
//  Created by Sergey Balashov on 13.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/**
 Has two cases. Designed for exclude `isFiatCalculation: Bool`
 - `typical` when the user edit `crypto` value and can see `fiat`only as secondary view
 - `alternative` when the user edit `fiat` value  and can see `crypto`only as secondary view
 */
enum CryptoFiatAmount: Hashable {
    case typical(crypto: Decimal?, fiat: Decimal?)
    case alternative(fiat: Decimal?, crypto: Decimal?)

    static let empty: CryptoFiatAmount = .typical(crypto: nil, fiat: nil)

    var fiat: Decimal? {
        switch self {
        case .typical(_, let fiat): fiat
        case .alternative(let fiat, _): fiat
        }
    }

    var crypto: Decimal? {
        switch self {
        case .typical(let crypto, _): crypto
        case .alternative(_, let crypto): crypto
        }
    }
}
