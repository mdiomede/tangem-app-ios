//
//  StakingCoordinator.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class StakingCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: StakingViewModel?

    // MARK: - Child coordinators

    // MARK: - Child view models

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        let builder = StakingStepsViewBuilder(userWalletName: options.userWalletModelName, wallet: options.walletModel)

        let stakingAmountViewModel = StakingAmountViewModel(
            walletModel: options.walletModel,
            input: builder.makeStakingAmountViewModel(),
            coordinator: self
        )

        rootViewModel = .init(step: .amount(stakingAmountViewModel), coordinator: self)
    }
}

// MARK: - Options

extension StakingCoordinator {
    struct Options {
        let userWalletModelName: String
        let walletModel: WalletModel
    }
}

// MARK: - StakingRoutable

extension StakingCoordinator: StakingRoutable {}

// MARK: - StakingAmountRoutable

extension StakingCoordinator: StakingAmountRoutable {}
