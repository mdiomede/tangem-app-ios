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
    @Published var animation: StepAnimation
    @Published var actionType: ActionType

    @Published var stakingAmountViewModel: StakingAmountViewModel
    @Published var stakingSummaryViewModel: StakingSummaryViewModel

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
        stakingSummaryViewModel = factory.makeStakingSummaryViewModel()

        // Intial setup
        animation = .fade
        actionType = .next
        step = .amount(stakingAmountViewModel)
    }

    func userDidTapActionButton() {
        switch actionType {
        case .next:
            openNextStep()
        }
    }

    func openNextStep() {
        switch step {
        case .none:
            break
        case .amount:
            step = .summary(stakingSummaryViewModel)

        case .summary:
            step = .amount(stakingAmountViewModel)
        }
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

    enum StepAnimation {
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

class StakingManager {
    private let amount: CurrentValueSubject<Decimal?, Never> = .init(nil)
}

extension StakingManager: StakingAmountOutput {
    func update(value: Decimal?) {
        amount.send(value)
    }
}

extension StakingManager: StakingSummaryInput, StakingAmountInput {
    func amountPublisher() -> AnyPublisher<Decimal?, Never> {
        amount.eraseToAnyPublisher()
    }
}

extension StakingManager: StakingSummaryOutput {}

class StakingModulesFactory {
    private let wallet: WalletModel
    private let builder: StakingStepsViewBuilder

    lazy var stakingManager = StakingManager()
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

    func makeStakingSummaryViewModel() -> StakingSummaryViewModel {
        StakingSummaryViewModel(
            inputModel: builder.makeStakingSummaryInput(),
            cryptoFiatAmountConverter: cryptoFiatAmountConverter,
            input: stakingManager,
            output: stakingManager
        )
    }
}
