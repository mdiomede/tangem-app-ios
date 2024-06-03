//
//  StakingSummaryViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 31.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

final class StakingSummaryViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var userWalletName: String
    @Published var tokenIconInfo: TokenIconInfo
    @Published var alternativeAmount: String?

    // MARK: - Dependencies

    private weak var output: StakingSummaryOutput?

    init(
        input: StakingSummaryViewModel.Input,
        output: StakingSummaryOutput
    ) {
        userWalletName = input.userWalletName
        tokenIconInfo = input.tokenIconInfo

        self.output = output
    }
}

extension StakingSummaryViewModel {
    struct Input {
        let userWalletName: String
        let tokenItem: TokenItem
        let tokenIconInfo: TokenIconInfo
        let validator: TransactionValidator
    }
}
