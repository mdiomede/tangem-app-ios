//
//  FeeSendStep.swift
//  Tangem
//
//  Created by Sergey Balashov on 26.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

struct FeeSendStep {
    private let _viewModel: SendFeeViewModel
    private let interactor: SendFeeInteractor
    private let notificationManager: SendNotificationManager
    private let tokenItem: TokenItem
    private let isFixedFee: Bool

    init(
        viewModel: SendFeeViewModel,
        interactor: SendFeeInteractor,
        notificationManager: SendNotificationManager,
        tokenItem: TokenItem,
        isFixedFee: Bool
    ) {
        _viewModel = viewModel
        self.interactor = interactor
        self.notificationManager = notificationManager
        self.tokenItem = tokenItem
        self.isFixedFee = isFixedFee
    }

    private func selectedFeeTypeAnalyticsParameter() -> Analytics.ParameterValue {
        if isFixedFee {
            return .transactionFeeFixed
        }

        switch interactor.selectedFee?.option {
        case .none:
            assertionFailure("selectedFeeTypeAnalyticsParameter not found")
            return .null
        case .slow:
            return .transactionFeeMin
        case .market:
            return .transactionFeeNormal
        case .fast:
            return .transactionFeeMax
        case .custom:
            return .transactionFeeCustom
        }
    }
}

// MARK: - SendStep

extension FeeSendStep: SendStep {
    var title: String? { Localization.commonFeeSelectorTitle }

    var type: SendStepName { .fee }

    var viewModel: SendFeeViewModel { _viewModel }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        interactor.selectedFeePublisher().map { $0 != nil }.eraseToAnyPublisher()
    }

    func makeView(namespace: Namespace.ID) -> some View {
        SendFeeView(viewModel: viewModel, namespace: namespace)
    }

    func canBeClosed(continueAction: @escaping () -> Void) -> Bool {
        let events = notificationManager.notificationInputs.compactMap { $0.settings.event as? SendNotificationEvent }
        for event in events {
            switch event {
            case .customFeeTooLow:
                Analytics.log(event: .sendNoticeTransactionDelaysArePossible, params: [
                    .token: tokenItem.currencySymbol,
                ])

                viewModel.alert = SendAlertBuilder.makeCustomFeeTooLowAlert(continueAction: continueAction)

                return false
            case .customFeeTooHigh(let orderOfMagnitude):
                viewModel.alert = SendAlertBuilder.makeCustomFeeTooHighAlert(orderOfMagnitude, continueAction: continueAction)

                return false
            default:
                break
            }
        }

        return true
    }

    func willClose(next step: any SendStep) {
        Analytics.log(event: .sendFeeSelected, params: [.feeType: selectedFeeTypeAnalyticsParameter().rawValue])
    }

    func willAppear(previous step: any SendStep) {
        interactor.updateFees()
    }
}
