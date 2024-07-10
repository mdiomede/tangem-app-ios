//
//  SendSummaryStepBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct SendSummaryStepBuilder {
    typealias IO = (input: SendSummaryInput, output: SendSummaryOutput)
    typealias ReturnValue = (step: SendSummaryStep, interactor: SendSummaryInteractor)

    let walletModel: WalletModel
    let builder: SendDependenciesBuilder

    func makeSendSummaryStep(
        io: IO,
        sendTransactionDispatcher: any SendTransactionDispatcher,
        notificationManager: NotificationManager,
        addressTextViewHeightModel: AddressTextViewHeightModel?,
        editableType: SendSummaryViewModel.EditableType,
        sendAmountCompactViewModel: SendAmountCompactViewModel?
    ) -> ReturnValue {
        let interactor = makeSendSummaryInteractor(
            io: io,
            sendTransactionDispatcher: sendTransactionDispatcher
        )

        let viewModel = makeSendSummaryViewModel(
            interactor: interactor,
            notificationManager: notificationManager,
            addressTextViewHeightModel: addressTextViewHeightModel,
            editableType: editableType,
            sendAmountCompactViewModel: sendAmountCompactViewModel
        )

        let step = SendSummaryStep(
            viewModel: viewModel,
            interactor: interactor,
            input: io.input,
            tokenItem: walletModel.tokenItem,
            walletName: builder.walletName()
        )

        return (step: step, interactor: interactor)
    }
}

// MARK: - Private

private extension SendSummaryStepBuilder {
    func makeSendSummaryViewModel(
        interactor: SendSummaryInteractor,
        notificationManager: NotificationManager,
        addressTextViewHeightModel: AddressTextViewHeightModel?,
        editableType: SendSummaryViewModel.EditableType,
        sendAmountCompactViewModel: SendAmountCompactViewModel?
    ) -> SendSummaryViewModel {
        let settings = SendSummaryViewModel.Settings(
            tokenItem: walletModel.tokenItem,
            editableType: editableType
        )

        return SendSummaryViewModel(
            settings: settings,
            interactor: interactor,
            notificationManager: notificationManager,
            addressTextViewHeightModel: addressTextViewHeightModel,
            sectionViewModelFactory: makeSendSummarySectionViewModelFactory(),
            sendAmountCompactViewModel: sendAmountCompactViewModel
        )
    }

    func makeSendSummaryInteractor(
        io: IO,
        sendTransactionDispatcher: any SendTransactionDispatcher
    ) -> SendSummaryInteractor {
        CommonSendSummaryInteractor(
            input: io.input,
            output: io.output,
            sendTransactionDispatcher: sendTransactionDispatcher,
            descriptionBuilder: makeSendTransactionSummaryDescriptionBuilder()
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

    func makeSendTransactionSummaryDescriptionBuilder() -> SendTransactionSummaryDescriptionBuilder {
        SendTransactionSummaryDescriptionBuilder(tokenItem: walletModel.tokenItem, feeTokenItem: walletModel.feeTokenItem)
    }
}
