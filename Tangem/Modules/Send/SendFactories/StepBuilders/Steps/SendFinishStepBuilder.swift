//
//  SendFinishStepBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendFinishStepBuilder {
    typealias ReturnValue = SendFinishStep

    let walletModel: WalletModel
    let builder: SendDependenciesBuilder

    func makeSendFinishStep(
        sendDestinationCompactViewModel: SendDestinationCompactViewModel?,
        sendAmountCompactViewModel: SendAmountCompactViewModel?,
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?,
        sendFeeCompactViewModel: SendFeeCompactViewModel?
    ) -> ReturnValue {
        let viewModel = makeSendFinishViewModel(
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            stakingValidatorsCompactViewModel: stakingValidatorsCompactViewModel,
            sendFeeCompactViewModel: sendFeeCompactViewModel
        )

        let step = SendFinishStep(viewModel: viewModel)

        return step
    }
}

// MARK: - Private

private extension SendFinishStepBuilder {
    func makeSendFinishViewModel(
        sendDestinationCompactViewModel: SendDestinationCompactViewModel?,
        sendAmountCompactViewModel: SendAmountCompactViewModel?,
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?,
        sendFeeCompactViewModel: SendFeeCompactViewModel?
    ) -> SendFinishViewModel {
        SendFinishViewModel(
            settings: .init(tokenItem: walletModel.tokenItem),
            sectionViewModelFactory: makeSendSummarySectionViewModelFactory(),
            feeAnalyticsParameterBuilder: builder.makeFeeAnalyticsParameterBuilder(),
            sendDestinationCompactViewModel: sendDestinationCompactViewModel,
            sendAmountCompactViewModel: sendAmountCompactViewModel,
            stakingValidatorsCompactViewModel: stakingValidatorsCompactViewModel,
            sendFeeCompactViewModel: sendFeeCompactViewModel
        )
    }

    func makeSendSummarySectionViewModelFactory() -> SendSummarySectionViewModelFactory {
        SendSummarySectionViewModelFactory(
            feeCurrencySymbol: walletModel.feeTokenItem.currencySymbol,
            feeCurrencyId: walletModel.feeTokenItem.currencyId,
            isFeeApproximate: builder.isFeeApproximate(),
            currencyId: walletModel.tokenItem.currencyId,
            tokenIconInfo: builder.makeTokenIconInfo()
        )
    }
}
