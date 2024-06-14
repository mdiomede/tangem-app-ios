//
//  CryptoFiatAmountFormatter.swift
//  Tangem
//
//  Created by Sergey Balashov on 14.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CryptoFiatAmountFormatter {
    private let currencySymbol: String
    private let balanceFormatter: BalanceFormatter

    private let formattingOptions = BalanceFormattingOptions(
        minFractionDigits: 0,
        maxFractionDigits: BalanceFormattingOptions.defaultCryptoFormattingOptions.maxFractionDigits,
        formatEpsilonAsLowestRepresentableValue: BalanceFormattingOptions.defaultCryptoFormattingOptions.formatEpsilonAsLowestRepresentableValue,
        roundingType: BalanceFormattingOptions.defaultCryptoFormattingOptions.roundingType
    )

    init(currencySymbol: String, balanceFormatter: BalanceFormatter = .init()) {
        self.currencySymbol = currencySymbol
        self.balanceFormatter = balanceFormatter
    }

    func format(amount: CryptoFiatAmount) -> String? {
        switch amount {
        case .empty:
            return nil
        case .typical(let cachedCrypto, _):
            return balanceFormatter.formatCryptoBalance(cachedCrypto, currencyCode: currencySymbol, formattingOptions: formattingOptions)
        case .alternative(let cachedFiat, _):
            return balanceFormatter.formatFiatBalance(cachedFiat)
        }
    }

    func formatAlternative(amount: CryptoFiatAmount) -> String? {
        switch amount {
        case .empty:
            return nil
        case .typical(_, let cachedFiat):
            return balanceFormatter.formatFiatBalance(cachedFiat)
        case .alternative(_, let cachedCrypto):
            return balanceFormatter.formatCryptoBalance(cachedCrypto, currencyCode: currencySymbol, formattingOptions: formattingOptions)
        }
    }
}
