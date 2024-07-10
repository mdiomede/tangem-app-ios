//
//  SendDestinationStep.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class SendDestinationStep {
    let viewModel: SendDestinationViewModel
    private let interactor: SendDestinationInteractor
    private let sendFeeInteractor: SendFeeInteractor
    private let tokenItem: TokenItem

    init(
        viewModel: SendDestinationViewModel,
        interactor: any SendDestinationInteractor,
        sendFeeInteractor: any SendFeeInteractor,
        tokenItem: TokenItem
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
        self.sendFeeInteractor = sendFeeInteractor
        self.tokenItem = tokenItem
    }

    func set(stepRouter: SendDestinationStepRoutable) {
        viewModel.stepRouter = stepRouter
    }
}

// MARK: - SendStep

extension SendDestinationStep: SendStep {
    var title: String? { Localization.sendRecipientLabel }

    var type: SendStepType { .destination(viewModel) }

    var sendStepViewAnimatable: (any SendStepViewAnimatable)? { nil }

    var navigationTrailingViewType: SendStepNavigationTrailingViewType? {
        .qrCodeButton { [weak self] in
            self?.viewModel.scanQRCode()
        }
    }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        interactor.destinationValid.eraseToAnyPublisher()
    }

    func willAppear(previous step: any SendStep) {
        switch step.type {
        case .summary:
            viewModel.transition = .offset() // SendView.StepAnimation.moveAndFade.transition
        case .amount:
            viewModel.transition = .move(edge: .leading) // SendView.StepAnimation.slideBackward.transition
        default:
            assertionFailure("Not implemented")
        }
    }

    func willDisappear(next step: SendStep) {
        UIApplication.shared.endEditing()

        guard step.type.isSummary else {
            return
        }

//        RunLoop.main.perform {
        viewModel.transition = .offset() // SendView.StepAnimation.moveAndFade.transition
//        }
//        viewModel.transition = SendView.StepAnimation.moveAndFade.transition
        sendFeeInteractor.updateFees()
    }
}
