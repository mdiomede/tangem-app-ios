//
//  SendViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

final class SendViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var step: SendStep
    @Published var currentStepInvalid: Bool = false

    var title: String {
        step.name
    }

    var showNavigationButtons: Bool {
        step.hasNavigationButtons
    }

    var showBackButton: Bool {
        previousStep != nil
    }

    var showNextButton: Bool {
        nextStep != nil
    }

    let sendAmountViewModel: SendAmountViewModel
    let sendDestinationViewModel: SendDestinationViewModel
    let sendFeeViewModel: SendFeeViewModel
    let sendSummaryViewModel: SendSummaryViewModel

    // MARK: - Dependencies

    private var nextStep: SendStep? {
        guard
            let currentStepIndex = steps.firstIndex(of: step),
            (currentStepIndex + 1) < steps.count
        else {
            return nil
        }

        return steps[currentStepIndex + 1]
    }

    private var previousStep: SendStep? {
        guard
            let currentStepIndex = steps.firstIndex(of: step),
            (currentStepIndex - 1) >= 0
        else {
            return nil
        }

        return steps[currentStepIndex - 1]
    }

    private let sendModel: SendModel
    private let sendType: SendType
    private let steps: [SendStep]

    private unowned let coordinator: SendRoutable

    private var currentStepValid: AnyPublisher<Bool, Never> {
        $step
            .flatMap { [weak self] step -> AnyPublisher<Bool, Never> in
                guard let self else {
                    return .just(output: true)
                }

                switch step {
                case .amount:
                    return sendModel.amountError
                        .map {
                            $0 == nil
                        }
                        .eraseToAnyPublisher()
                case .destination:
                    return Publishers.CombineLatest(sendModel.destinationError, sendModel.destinationAdditionalFieldError)
                        .map {
                            $0 == nil && $1 == nil
                        }
                        .eraseToAnyPublisher()
                case .fee:
                    return .just(output: true)
                case .summary:
                    return .just(output: true)
                }
            }
            .eraseToAnyPublisher()
    }

    init(sendType: SendType, coordinator: SendRoutable) {
        self.coordinator = coordinator
        sendModel = SendModel()
        self.sendType = sendType

        let steps = sendType.steps
        guard let firstStep = steps.first else {
            fatalError("No steps provided for the send type")
        }
        self.steps = steps
        step = firstStep

        sendAmountViewModel = SendAmountViewModel(input: sendModel)
        sendDestinationViewModel = SendDestinationViewModel(input: sendModel)
        sendFeeViewModel = SendFeeViewModel(input: sendModel)
        sendSummaryViewModel = SendSummaryViewModel(input: sendModel)

        sendAmountViewModel.delegate = self
        sendSummaryViewModel.router = self

        bind()
    }

    func next() {
        guard let nextStep else {
            assertionFailure("Invalid step logic -- next")
            return
        }

        step = nextStep
    }

    func back() {
        guard let previousStep else {
            assertionFailure("Invalid step logic -- back")
            return
        }

        step = previousStep
    }

    private func bind() {
        currentStepValid
            .map {
                !$0
            }
            .assign(to: &$currentStepInvalid)
    }
}

extension SendViewModel: SendSummaryRoutable {
    func openStep(_ step: SendStep) {
        self.step = step
    }

    func send() {
        sendModel.send()
    }
}

extension SendViewModel: SendAmountViewModelDelegate {
    func didTapMaxAmount() {
        sendModel.useMaxAmount()
    }
}
