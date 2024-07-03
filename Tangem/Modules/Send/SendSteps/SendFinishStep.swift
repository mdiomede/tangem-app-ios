//
//  SendFinishStep.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

struct SendFinishStep {
    private let _viewModel: SendFinishViewModel
    private let tokenItem: TokenItem
    private let sendFeeInteractor: SendFeeInteractor
    private let feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder

    init(
        viewModel: SendFinishViewModel,
        tokenItem: TokenItem,
        sendFeeInteractor: SendFeeInteractor,
        feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder
    ) {
        _viewModel = viewModel
        self.tokenItem = tokenItem
        self.sendFeeInteractor = sendFeeInteractor
        self.feeAnalyticsParameterBuilder = feeAnalyticsParameterBuilder
    }

    private func onAppear() {
        let feeType = feeAnalyticsParameterBuilder.analyticsParameter(selectedFee: sendFeeInteractor.selectedFee?.option)
        Analytics.log(event: .sendTransactionSentScreenOpened, params: [
            .token: tokenItem.currencySymbol,
            .feeType: feeType.rawValue,
        ])
    }
}

extension SendFinishStep: SendStep {
    var title: String? { nil }

    var type: SendStepType { .finish }

    var viewModel: SendFinishViewModel { _viewModel }

    func makeView(namespace: Namespace.ID) -> AnyView {
        AnyView(
            SendFinishView(viewModel: viewModel, namespace: namespace)
                .onAppear(perform: onAppear)
        )
    }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        .just(output: true)
    }
}
