//
//  StakingSummaryViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 31.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class StakingSummaryViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var tokenIconInfo: TokenIconInfo

    // MARK: - Dependencies

    private weak var coordinator: StakingSummaryRoutable?

    init(
        walletModel: WalletModel,
        coordinator: StakingSummaryRoutable
    ) {


        tokenIconInfo = TokenIconInfoBuilder().build(from: walletModel.tokenItem, isCustom: walletModel.isCustom)

        self.coordinator = coordinator
    }
}

extension StakingSummaryViewModel {
    struct Input {
        let userWalletName: String
        let tokenItem: TokenItem
        let tokenIconInfo: TokenIconInfo
    }
}
