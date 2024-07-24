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
//    @Published var deselectedFeeRowViewModels: [FeeRowViewModel] = []

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

    func onAppear() {
//        selectedFeeSummaryViewModel?.setAnimateTitleOnAppear(true)
    }

    func bind(input: SendFeeInput) {
        inputSubscription = Publishers.CombineLatest(input.feesPublisher, input.selectedFeePublisher)
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, args in
                let (feeValues, selectedFee) = args
                viewModel.selectedFeeRowViewModel = viewModel.mapToFeeRowViewModel(fee: selectedFee)
//                viewModel.deselectedFeeRowViewModels = feeValues
//                    .filter { $0.option != selectedFee.option }
//                    .map { feeValue in
//                        viewModel.makeDeselectedFeeRowViewModel(from: feeValue)
//                    }
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

//    private func makeDeselectedFeeRowViewModel(from value: SendFee) -> FeeRowViewModel {
//        return FeeRowViewModel(
//            option: value.option,
//            formattedFeeComponents: formattedFeeComponents(from: value.value),
//            isSelected: .constant(false)
//        )
//    }

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
