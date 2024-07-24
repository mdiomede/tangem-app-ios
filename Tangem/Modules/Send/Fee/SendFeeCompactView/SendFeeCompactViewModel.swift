//
//  SendFeeCompactViewModel.swift
//  Tangem
//
//  Created by Sergey Balashov on 24.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class SendFeeCompactViewModel: ObservableObject, Identifiable {
    @Published var selectedFeeRowViewModel: FeeRowViewModel?

    private let feeTokenItem: TokenItem
    private let isFeeApproximate: Bool
    private var inputSubscription: AnyCancellable?

    private let feeFormatter: FeeFormatter = CommonFeeFormatter(
        balanceFormatter: BalanceFormatter(),
        balanceConverter: BalanceConverter()
    )

    init(
        input: SendFeeInput,
        feeTokenItem: TokenItem,
        isFeeApproximate: Bool
    ) {
        self.feeTokenItem = feeTokenItem
        self.isFeeApproximate = isFeeApproximate
    }

    func bind(input: SendFeeInput) {
        inputSubscription = input.selectedFeePublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, selectedFee in
                viewModel.selectedFeeRowViewModel = viewModel.mapToFeeRowViewModel(fee: selectedFee)
            }
    }

    private func mapToFeeRowViewModel(fee: SendFee) -> FeeRowViewModel {
        let feeComponents = formattedFeeComponents(from: fee.value)

        return FeeRowViewModel(
            option: fee.option,
            formattedFeeComponents: feeComponents,
            isSelected: .constant(true)
        )
    }

    private func makeFeeViewData(from value: SendFee) -> SendFeeSummaryViewModel? {
        let formattedFeeComponents = formattedFeeComponents(from: value.value)
        return SendFeeSummaryViewModel(
            title: Localization.commonNetworkFeeTitle,
            feeOption: value.option,
            formattedFeeComponents: formattedFeeComponents
        )
    }

    private func formattedFeeComponents(from feeValue: LoadingValue<Fee>) -> LoadingValue<FormattedFeeComponents> {
        switch feeValue {
        case .loading:
            return .loading
        case .loaded(let value):
            let formattedFeeComponents = feeFormatter.formattedFeeComponents(
                fee: value.amount.value,
                currencySymbol: feeTokenItem.currencySymbol,
                currencyId: feeTokenItem.currencyId,
                isFeeApproximate: isFeeApproximate
            )
            return .loaded(formattedFeeComponents)
        case .failedToLoad(let error):
            return .failedToLoad(error: error)
        }
    }
}
