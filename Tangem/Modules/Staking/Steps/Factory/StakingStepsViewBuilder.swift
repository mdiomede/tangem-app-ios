//
//  StakingStepsViewBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 31.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct StakingStepsViewBuilder {
    let userWalletName: String
    let wallet: WalletModel

    func makeStakingAmountViewModel() -> StakingAmountViewModel.Input {
        let tokenIconInfo = TokenIconInfoBuilder().build(
            from: wallet.tokenItem,
            isCustom: wallet.isCustom
        )

        let balanceFormatted = BalanceFormatter().formatCryptoBalance(
            wallet.balanceValue,
            currencyCode: wallet.tokenItem.currencySymbol
        )

        return .init(
            userWalletName: userWalletName,
            tokenItem: wallet.tokenItem,
            tokenIconInfo: tokenIconInfo,
            balanceFormatted: balanceFormatted
        )
    }
}
