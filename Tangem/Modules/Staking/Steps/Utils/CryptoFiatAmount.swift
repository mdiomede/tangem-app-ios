//
//  CryptoFiatAmount.swift
//  Tangem
//
//  Created by Sergey Balashov on 04.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

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
