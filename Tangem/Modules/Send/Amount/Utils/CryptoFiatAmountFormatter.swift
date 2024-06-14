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

    func format(amount: CryptoFiatAmount?) -> String? {
        switch amount {
        case .none:
            return nil
        case .typical(let crypto, _):
            return balanceFormatter.formatCryptoBalance(crypto, currencyCode: currencySymbol, formattingOptions: formattingOptions)
        case .alternative(let fiat, _):
            return fiat.map { balanceFormatter.formatFiatBalance($0) }
        }
    }

    func formatAlternative(amount: CryptoFiatAmount?) -> String? {
        switch amount {
        case .none:
            return nil
        case .typical(_, let fiat):
            return fiat.map { balanceFormatter.formatFiatBalance($0) }
        case .alternative(_, let crypto):
            return balanceFormatter.formatCryptoBalance(crypto, currencyCode: currencySymbol, formattingOptions: formattingOptions)
        }
    }
}
