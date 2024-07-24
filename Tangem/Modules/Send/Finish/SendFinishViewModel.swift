//
//  SendFinishViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 03.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class SendFinishViewModel: ObservableObject, Identifiable {
    @Published var showHeader = false
    @Published var transactionSentTime: String?
    @Published var alert: AlertBinder?

    @Published var sendDestinationCompactViewModel: SendDestinationCompactViewModel?
    @Published var sendAmountCompactViewModel: SendAmountCompactViewModel?
    @Published var stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?
    @Published var sendFeeCompactViewModel: SendFeeCompactViewModel?

    private let tokenItem: TokenItem
    private let feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder

    private var feeTypeAnalyticsParameter: Analytics.ParameterValue = .null
    private var bag: Set<AnyCancellable> = []

    init(
        settings: Settings,
        feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder,
        sendDestinationCompactViewModel: SendDestinationCompactViewModel?,
        sendAmountCompactViewModel: SendAmountCompactViewModel?,
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?,
        sendFeeCompactViewModel: SendFeeCompactViewModel?
    ) {
        tokenItem = settings.tokenItem

        self.feeAnalyticsParameterBuilder = feeAnalyticsParameterBuilder
        self.sendDestinationCompactViewModel = sendDestinationCompactViewModel
        self.sendAmountCompactViewModel = sendAmountCompactViewModel
        self.stakingValidatorsCompactViewModel = stakingValidatorsCompactViewModel
        self.sendFeeCompactViewModel = sendFeeCompactViewModel
    }

    func onAppear() {
        Analytics.log(event: .sendTransactionSentScreenOpened, params: [
            .token: tokenItem.currencySymbol,
            .feeType: feeTypeAnalyticsParameter.rawValue,
        ])

        withAnimation(SendView.Constants.defaultAnimation) {
            showHeader = true
        }
    }
}

extension SendFinishViewModel {
    struct Settings {
        let tokenItem: TokenItem
    }
}
