//
//  SendTransactionSummaryDescriptionBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendTransactionSummaryDescriptionBuilder {
    private let feeCurrency: TokenItem

    init(feeCurrency: TokenItem) {
        self.feeCurrency = feeCurrency
    }

    func makeDescription(amount: SendAmount, fee: Decimal) -> String? {
        let feeInFiat = feeCurrency.id.flatMap { BalanceConverter().convertToFiat(fee, currencyId: $0) }
        let totalInFiat = [amount.fiat, feeInFiat].compactMap { $0 }.reduce(0, +)

        let formattingOptions = BalanceFormattingOptions(
            minFractionDigits: BalanceFormattingOptions.defaultFiatFormattingOptions.minFractionDigits,
            maxFractionDigits: BalanceFormattingOptions.defaultFiatFormattingOptions.maxFractionDigits,
            formatEpsilonAsLowestRepresentableValue: true,
            roundingType: BalanceFormattingOptions.defaultFiatFormattingOptions.roundingType
        )

        let formatter = BalanceFormatter()
        let totalInFiatFormatted = formatter.formatFiatBalance(totalInFiat, formattingOptions: formattingOptions)
        let feeInFiatFormatted = formatter.formatFiatBalance(feeInFiat, formattingOptions: formattingOptions)

        return Localization.sendSummaryTransactionDescription(totalInFiatFormatted, feeInFiatFormatted)
    }
}
