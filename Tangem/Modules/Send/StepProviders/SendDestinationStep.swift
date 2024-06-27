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

struct SendDestinationStep {
    private let _viewModel: SendDestinationViewModel
    private let interactor: SendDestinationInteractor
    private let sendFeeInteractor: SendFeeInteractor

    init(
        viewModel: SendDestinationViewModel,
        interactor: SendDestinationInteractor,
        sendFeeInteractor: SendFeeInteractor
    ) {
        _viewModel = viewModel
        self.interactor = interactor
        self.sendFeeInteractor = sendFeeInteractor
    }
}

extension SendDestinationStep: SendStep {
    var title: String? { Localization.sendRecipientLabel }

    var type: SendStepName { .destination }

    var viewModel: SendDestinationViewModel { _viewModel }

    func makeView(namespace: Namespace.ID) -> some View {
        SendDestinationView(viewModel: viewModel, namespace: namespace)
    }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        interactor.destinationValid.eraseToAnyPublisher()
    }

    func willClose(next step: any SendStep) {
        guard step.type == .summary else {
            return
        }

        sendFeeInteractor.updateFees()
    }
}
