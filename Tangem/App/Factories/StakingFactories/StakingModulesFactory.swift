//
//  StakingModulesFactory.swift
//  Tangem
//
//  Created by Sergey Balashov on 04.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

class StakingModulesFactory {
    private let userWalletName: String
    private let wallet: WalletModel
    private let yield: YieldInfo
    private let builder: StakingStepsViewBuilder

    lazy var stakingManager = makeStakingManager()
    lazy var cryptoFiatAmountConverter = CryptoFiatAmountConverter()

    init(userWalletName: String, wallet: WalletModel, yield: YieldInfo) {
        self.userWalletName = userWalletName
        self.wallet = wallet
        self.yield = yield
        builder = .init(userWalletName: userWalletName, wallet: wallet, yield: yield)
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

    func makeStakingValidatorsViewModel(coordinator: StakingValidatorsRoutable) -> StakingValidatorsViewModel {
        StakingValidatorsViewModel(
            inputModel: builder.makeStakingValidatorsInput(),
            input: stakingManager,
            output: stakingManager,
            coordinator: coordinator
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

    // MARK: - Services

    func makeStakingManager() -> StakingManager {
        StakingManager(wallet: wallet, yield: yield, converter: cryptoFiatAmountConverter)
    }
}
