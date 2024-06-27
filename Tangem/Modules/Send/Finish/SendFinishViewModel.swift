//
//  SendFinishViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 16.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BlockchainSdk

class SendFinishViewModel: ObservableObject {
    @Published var showHeader = false
    @ObservedObject var addressTextViewHeightModel: AddressTextViewHeightModel

    let transactionTime: String

    let destinationViewTypes: [SendDestinationSummaryViewType]
    let amountSummaryViewData: SendAmountSummaryViewData?
    let feeSummaryViewData: SendFeeSummaryViewModel?

    private let tokenItem: TokenItem

    init?(
        initial: Initial,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        sectionViewModelFactory: SendSummarySectionViewModelFactory
    ) {
        tokenItem = initial.tokenItem
        destinationViewTypes = sectionViewModelFactory.makeDestinationViewTypes(
            address: initial.destination,
            additionalField: initial.additionalField
        )

        amountSummaryViewData = sectionViewModelFactory.makeAmountViewData(
            amount: initial.amount.format(currencySymbol: initial.tokenItem.currencySymbol),
            amountAlternative: initial.amount.formatAlternative(currencySymbol: initial.tokenItem.currencySymbol)
        )

        feeSummaryViewData = sectionViewModelFactory.makeFeeViewData(from: initial.feeValue)
        transactionTime = initial.transactionTimeFormatted

        self.addressTextViewHeightModel = addressTextViewHeightModel
    }

    func onAppear() {


        withAnimation(SendView.Constants.defaultAnimation) {
            showHeader = true
        }
    }
}

extension SendFinishViewModel {
    struct Initial {
        let tokenItem: TokenItem
        let destination: String
        let additionalField: DestinationAdditionalFieldType
        let amount: SendAmount
        let feeValue: SendFee
        let transactionTimeFormatted: String
    }
}
