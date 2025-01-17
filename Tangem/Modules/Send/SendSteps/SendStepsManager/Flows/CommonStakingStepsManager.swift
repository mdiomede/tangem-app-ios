//
//  CommonStakingStepsManager.swift
//  Tangem
//
//  Created by Sergey Balashov on 10.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class CommonStakingStepsManager {
    private let amountStep: SendAmountStep
    private let validatorsStep: StakingValidatorsStep
    private let summaryStep: SendSummaryStep
    private let finishStep: SendFinishStep

    private var stack: [SendStep]
    private weak var output: SendStepsManagerOutput?

    init(
        amountStep: SendAmountStep,
        validatorsStep: StakingValidatorsStep,
        summaryStep: SendSummaryStep,
        finishStep: SendFinishStep
    ) {
        self.amountStep = amountStep
        self.validatorsStep = validatorsStep
        self.summaryStep = summaryStep
        self.finishStep = finishStep

        stack = [amountStep]
    }

    private func currentStep() -> SendStep {
        let last = stack.last

        assert(last != nil, "Stack is empty")

        return last ?? initialState.step
    }

    private func getNextStep() -> (SendStep)? {
        switch currentStep().type {
        case .amount:
            return summaryStep
        case .destination, .fee, .validators, .summary, .finish:
            assertionFailure("There is no next step")
            return nil
        }
    }

    private func next(step: SendStep) {
        let isEditAction = stack.contains(where: { $0.type.isSummary })
        stack.append(step)

        switch step.type {
        case .summary:
            output?.update(state: .init(step: step, action: .action))
        case .finish:
            output?.update(state: .init(step: step, action: .close))
        case .amount where isEditAction, .validators where isEditAction:
            output?.update(state: .init(step: step, action: .continue))
        case .amount, .destination, .validators, .fee:
            assertionFailure("There is no next step")
        }
    }

    private func back() {
        stack.removeLast()
        let step = currentStep()

        switch step.type {
        case .summary:
            output?.update(state: .init(step: step, action: .action))
        default:
            assertionFailure("There is no back step")
        }
    }
}

// MARK: - SendStepsManager

extension CommonStakingStepsManager: SendStepsManager {
    var initialFlowActionType: SendFlowActionType { .stake }

    var initialState: SendStepsManagerViewState {
        .init(step: amountStep, action: .next, backButtonVisible: false)
    }

    func set(output: SendStepsManagerOutput) {
        self.output = output
    }

    func performBack() {
        back()
    }

    func performNext() {
        guard let step = getNextStep() else {
            return
        }

        func openNext() {
            next(step: step)
        }

        guard currentStep().canBeClosed(continueAction: openNext) else {
            return
        }

        openNext()
    }

    func performFinish() {
        next(step: finishStep)
    }

    func performContinue() {
        assert(stack.contains(where: { $0.type.isSummary }), "Continue is possible only after summary")

        back()
    }
}

// MARK: - SendSummaryStepsRoutable

extension CommonStakingStepsManager: SendSummaryStepsRoutable {
    func summaryStepRequestEditValidators() {
        guard case .summary = currentStep().type else {
            assertionFailure("This code should only be called from summary")
            return
        }

        next(step: validatorsStep)
    }

    func summaryStepRequestEditAmount() {
        guard case .summary = currentStep().type else {
            assertionFailure("This code should only be called from summary")
            return
        }

        next(step: amountStep)
    }

    func summaryStepRequestEditDestination() {
        assertionFailure("This steps is not tappable in this flow")
    }

    func summaryStepRequestEditFee() {
        assertionFailure("This steps is not tappable in this flow")
    }
}
