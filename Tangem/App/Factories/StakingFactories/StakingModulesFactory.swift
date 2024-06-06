//
//  StakingModulesFactory.swift
//  Tangem
//
//  Created by Sergey Balashov on 04.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class StakingModulesFactory {
    private let wallet: WalletModel
    private let builder: StakingStepsViewBuilder

    lazy var stakingManager = makeStakingManager()
    lazy var cryptoFiatAmountConverter = CryptoFiatAmountConverter()

    init(wallet: WalletModel, builder: StakingStepsViewBuilder) {
        self.wallet = wallet
        self.builder = builder
    }

    func makeStakingDetailsViewModel(coordinator: StakingDetailsRoutable) -> StakingDetailsViewModel {
        StakingDetailsViewModel(wallet: wallet, coordinator: coordinator)
    }

    func makeStakingViewModel(coordinator: StakingRoutable) -> StakingViewModel {
        StakingViewModel(factory: self, coordinator: coordinator)
    }

    func makeStakingAmountViewModel() -> StakingAmountViewModel {
        StakingAmountViewModel(
            inputModel: builder.makeStakingAmountInput(),
            cryptoFiatAmountConverter: cryptoFiatAmountConverter,
            input: stakingManager,
            output: stakingManager
        )
    }

    func makeStakingSummaryViewModel(router: StakingSummaryRoutable) -> StakingSummaryViewModel {
        StakingSummaryViewModel(
            inputModel: builder.makeStakingSummaryInput(),
            input: stakingManager,
            output: stakingManager,
            router: router
        )
    }

    func makeStakingManager() -> StakingManager {
        StakingManager(wallet: wallet, converter: cryptoFiatAmountConverter)
    }
}
