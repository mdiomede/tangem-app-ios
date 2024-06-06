//
//  StakingStepsViewBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 31.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

struct StakingStepsViewBuilder {
    let userWalletName: String
    let wallet: WalletModel
    let yield: YieldInfo

    func makeStakingAmountInput() -> StakingAmountViewModel.Input {
        let tokenIconInfo = TokenIconInfoBuilder().build(
            from: wallet.tokenItem,
            isCustom: wallet.isCustom
        )

        let balanceFormatted = BalanceFormatter().formatCryptoBalance(
            wallet.balanceValue,
            currencyCode: wallet.tokenItem.currencySymbol
        )

        let fiatIconURL = IconURLBuilder().fiatIconURL(currencyCode: AppSettings.shared.selectedCurrencyCode)
        let currencyPickerData = SendCurrencyPickerData(
            cryptoIconURL: tokenIconInfo.imageURL,
            cryptoCurrencyCode: wallet.tokenItem.currencySymbol,
            fiatIconURL: fiatIconURL,
            fiatCurrencyCode: AppSettings.shared.selectedCurrencyCode,
            disabled: wallet.quote == nil
        )

        return .init(
            userWalletName: userWalletName,
            tokenItem: wallet.tokenItem,
            tokenIconInfo: tokenIconInfo,
            balanceValue: wallet.balanceValue ?? 0,
            balanceFormatted: balanceFormatted,
            currencyPickerData: currencyPickerData,
            validator: wallet.transactionValidator
        )
    }

    func makeStakingValidatorsInput() -> StakingValidatorsViewModel.Input {
        return .init(validators: yield.validators)
    }

    func makeStakingSummaryInput() -> StakingSummaryViewModel.Input {
        let tokenIconInfo = TokenIconInfoBuilder().build(
            from: wallet.tokenItem,
            isCustom: wallet.isCustom
        )

        return .init(
            userWalletName: userWalletName,
            tokenItem: wallet.tokenItem,
            tokenIconInfo: tokenIconInfo,
            validator: wallet.transactionValidator
        )
    }
}
