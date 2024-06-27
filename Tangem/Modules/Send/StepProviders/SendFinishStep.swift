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
        private let feeTypeAnalyticsParameter: Analytics.ParameterValue

    init(
        viewModel: SendFinishViewModel,
        tokenItem: TokenItem,
        feeTypeAnalyticsParameter: Analytics.ParameterValue
    ) {
        _viewModel = viewModel
        self.tokenItem = tokenItem
        self.feeTypeAnalyticsParameter = feeTypeAnalyticsParameter
    }

    private func log() {
        Analytics.log(event: .sendTransactionSentScreenOpened, params: [
            .token: tokenItem.currencySymbol,
            .feeType: feeTypeAnalyticsParameter.rawValue,
        ])
    }
}

extension SendFinishStep: SendStep {
    var title: String? { nil }

    var type: SendStepName { .finish }

    var viewModel: SendFinishViewModel { _viewModel }

    func makeView(namespace: Namespace.ID) -> some View {
        SendFinishView(viewModel: viewModel, namespace: namespace)
            .onAppear {
                log()
            }
    }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        .just(output: true)
    }
}
