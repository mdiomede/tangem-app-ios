//
//  StakingViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemStaking

final class StakingViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var step: Step?
    @Published var animation: AnimationType = .fade
    @Published var action: ActionType = .next

    @Published var stakingAmountViewModel: StakingAmountViewModel?
    @Published var stakingSummaryViewModel: StakingSummaryViewModel?
    @Published var stakingValidatorsViewModel: StakingValidatorsViewModel?

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
        case .validators:
            step = stakingValidatorsViewModel.map { .validators($0) }
        }
    }
}

extension StakingViewModel: StakingValidatorsRoutable {
    func userDidSelectedValidator() {
        step = stakingSummaryViewModel.map { .summary($0) }
    }
}

extension StakingViewModel: StakingSummaryRoutable {
    func openAmountStep() {
        step = stakingAmountViewModel.map { .amount($0) }
    }

    func openValidatorsStep() {
        step = stakingValidatorsViewModel.map { .validators($0) }
    }
}

extension StakingViewModel {
    enum Step: Equatable {
        case amount(StakingAmountViewModel)
        case summary(StakingSummaryViewModel)
        case validators(StakingValidatorsViewModel)

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
