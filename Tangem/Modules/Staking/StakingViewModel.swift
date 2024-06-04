//
//  StakingViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class StakingViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var step: Step?
    @Published var animation: AnimationType = .fade
    @Published var action: ActionType = .next

    @Published var stakingAmountViewModel: StakingAmountViewModel?
    @Published var stakingSummaryViewModel: StakingSummaryViewModel?

    @Published var stakingAmountViewModel: StakingAmountViewModel?
    @Published var stakingSummaryViewModel: StakingSummaryViewModel?

    // MARK: - Dependencies

    private let factory: StakingModulesFactory
    private weak var coordinator: StakingRoutable?

    init(
        factory: StakingModulesFactory,
        coordinator: StakingRoutable
    ) {
        self.factory = factory
        self.coordinator = coordinator

        stakingAmountViewModel = factory.makeStakingAmountViewModel()
        stakingSummaryViewModel = factory.makeStakingSummaryViewModel(router: self)

        // Intial setup
        animation = .fade
        action = .next
        step = stakingAmountViewModel.map { .amount($0) }
    }

    func userDidTapActionButton() {
        switch action {
        case .next:
            openNextStep()
        }
    }

    func openNextStep() {
        switch step {
        case .none:
            break
        case .amount:
            step = stakingSummaryViewModel.map { .summary($0) }
        case .summary:
            step = stakingAmountViewModel.map { .amount($0) }
        }
    }
}

extension StakingViewModel: StakingSummaryRoutable {
    func openAmountStep() {
        step = stakingAmountViewModel.map { .amount($0) }
    }
}

extension StakingViewModel {
    enum Step: Equatable {
        case amount(StakingAmountViewModel)
        case summary(StakingSummaryViewModel)

        static func == (lhs: StakingViewModel.Step, rhs: StakingViewModel.Step) -> Bool {
            switch (lhs, rhs) {
            case (.amount, .amount): true
            case (.summary, .summary): true
            default: false
            }
        }
    }

    enum AnimationType {
        case slideForward
        case slideBackward
        case fade
    }

    enum ActionType {
        case next

        var title: String {
            switch self {
            case .next:
                return Localization.commonNext
            }
        }
    }
}

class StakingModulesFactory {
    private let wallet: WalletModel
    private let builder: StakingStepsViewBuilder

    lazy var stakingManager = makeStakingManager()
    lazy var cryptoFiatAmountConverter = CryptoFiatAmountConverter()

    init(wallet: WalletModel, builder: StakingStepsViewBuilder) {
        self.wallet = wallet
        self.builder = builder
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
