//
//  StakingViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

class StakingManager {}

extension StakingManager: StakingAmountOutput {}
extension StakingManager: StakingSummaryOutput {}

final class StakingViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var step: Step
    @Published var actionType: ActionType

    // MARK: - Dependencies

    private let manager: StakingManager
    private let builder: StakingStepsViewBuilder
    private weak var coordinator: StakingRoutable?

    init(
        manager: StakingManager,
        builder: StakingStepsViewBuilder,
        coordinator: StakingRoutable
    ) {
        self.manager = manager
        self.builder = builder
        self.coordinator = coordinator

        // Intial setup
        step = .amount(StakingAmountViewModel(input: builder.makeStakingAmountInput(), coordinator: manager))
        actionType = .continue
    }

    func userDidTapActionButton() {
        switch actionType {
        case .continue:
            openNextStep()
        }
    }

    func openNextStep() {
        switch step {
        case .amount:
            let viewModel = StakingAmountViewModel(input: builder.makeStakingAmountInput(), coordinator: manager)
            step = .summary(<#T##StakingSummaryViewModel#>)
        case .summary:
            assertionFailure("There's no next step")
        }
    }
}

extension StakingViewModel {
    enum Step {
        case amount(StakingAmountViewModel)
        case summary(StakingSummaryViewModel)
    }

    enum ActionType {
        case `continue`
    }
}
