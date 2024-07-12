//
//  StakingModulesFactory.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

class StakingModulesFactory {
    @Injected(\.stakingRepositoryProxy) private var stakingRepositoryProxy: StakingRepositoryProxy

    private let userWalletModel: UserWalletModel
    private let walletModel: WalletModel

    init(userWalletModel: UserWalletModel, walletModel: WalletModel) {
        self.userWalletModel = userWalletModel
        self.walletModel = walletModel
    }

    func makeStakingDetailsViewModel(coordinator: StakingDetailsRoutable) -> StakingDetailsViewModel {
        StakingDetailsViewModel(
            userWalletModel: userWalletModel,
            walletModel: walletModel,
            stakingRepository: stakingRepositoryProxy,
            coordinator: coordinator
        )
    }

    func makeStakingFlow(
        yield: YieldInfo,
        dismissAction: @escaping Action<(walletModel: WalletModel, userWalletModel: UserWalletModel)?>
    ) -> SendCoordinator {
        let coordinator = SendCoordinator(dismissAction: dismissAction)
        let options = SendCoordinator.Options(
            walletModel: walletModel,
            userWalletModel: userWalletModel,
            type: .staking(manager: makeStakingManager(yield: yield))
        )
        coordinator.start(with: options)
        return coordinator
    }

    // MARK: - Dependencies

    func makeStakingManager(yield: YieldInfo) -> StakingManager {
        let provider = StakingDependenciesFactory().makeStakingAPIProvider()
        return TangemStakingFactory().makeStakingManager(
            wallet: walletModel,
            provider: provider,
            yield: yield,
            logger: AppLog.shared
        )
    }
}
