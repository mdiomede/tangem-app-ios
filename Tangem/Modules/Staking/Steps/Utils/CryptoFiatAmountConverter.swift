//
//  CryptoFiatAmountConverter.swift
//  Tangem
//
//  Created by Sergey Balashov on 03.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class CryptoFiatAmountConverter {
    private let formatter: DecimalNumberFormatter
    private var cached: Cache?

    init(maximumFractionDigits: Int) {
        formatter = DecimalNumberFormatter(maximumFractionDigits: maximumFractionDigits)
    }

    func convertToCrypto(_ fiatValue: Decimal?, tokenItem: TokenItem) -> Decimal? {
        if cached?.fiat == fiatValue {
            return cached?.crypto
        }

        guard let fiatValue,
              let currencyId = tokenItem.currencyId,
              let cryptoValue = BalanceConverter().convertFromFiat(fiatValue, currencyId: currencyId) else {
            return nil
        }

        formatter.update(maximumFractionDigits: tokenItem.decimalCount)
        let formatted: Decimal? = formatter.format(value: cryptoValue)
        cached = Cache(fiat: fiatValue, crypto: formatted)

        return formatted
    }

    func convertToFiat(_ cryptoValue: Decimal?, tokenItem: TokenItem) -> Decimal? {
        if cached?.crypto == cryptoValue {
            return cached?.fiat
        }

        guard let cryptoValue,
              let currencyId = tokenItem.currencyId,
              let fiatValue = BalanceConverter().convertToFiat(cryptoValue, currencyId: currencyId) else {
            return nil
        }

        formatter.update(maximumFractionDigits: 2)
        let formatted: Decimal? = formatter.format(value: fiatValue)
        cached = Cache(fiat: formatted, crypto: cryptoValue)

        return formatted
    }
}

extension CryptoFiatAmountConverter {
    struct Cache: Hashable {
        let fiat: Decimal?
        let crypto: Decimal?
    }
}
