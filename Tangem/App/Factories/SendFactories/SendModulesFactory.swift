//
//  SendModulesFactory.swift
//  Tangem
//
//  Created by Sergey Balashov on 08.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct SendModulesFactory {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let userWalletModel: UserWalletModel
    private let walletModel: WalletModel
    private let builder: SendModulesStepsBuilder

    init(userWalletModel: UserWalletModel, walletModel: WalletModel) {
        self.userWalletModel = userWalletModel
        self.walletModel = walletModel

        builder = .init(userWalletName: userWalletModel.name, walletModel: walletModel)
    }

    // MARK: - ViewModels

    func makeSendViewModel(type: SendType, coordinator: SendRoutable) -> SendViewModel {
        let sendFeeInteractor = makeSendFeeInteractor(
            predefinedAmount: type.predefinedAmount,
            predefinedDestination: type.predefinedDestination
        )

        let sendModel = makeSendModel(type: type, sendFeeInteractor: sendFeeInteractor)
        let canUseFiatCalculation = quotesRepository.quote(for: walletModel.tokenItem) != nil
        let walletInfo = builder.makeSendWalletInfo(canUseFiatCalculation: canUseFiatCalculation)
        let initial = SendViewModel.Initial(feeOptions: builder.makeFeeOptions())
        sendFeeInteractor.setup(input: sendModel, output: sendModel)

        return SendViewModel(
            initial: initial,
            walletInfo: walletInfo,
            walletModel: walletModel,
            userWalletModel: userWalletModel,
            transactionSigner: transactionSigner,
            sendType: type,
            emailDataProvider: emailDataProvider,
            sendModel: sendModel,
            notificationManager: makeSendNotificationManager(sendModel: sendModel),
            sendFeeInteractor: sendFeeInteractor,
            keyboardVisibilityService: KeyboardVisibilityService(),
            sendAmountValidator: makeSendAmountValidator(),
            factory: self,
            processor: makeSendDestinationProcessor(),
            coordinator: coordinator
        )
    }

    func makeSendDestinationViewModel(
        input: SendDestinationInput,
        output: SendDestinationOutput,
        sendType: SendType,
        addressTextViewHeightModel: AddressTextViewHeightModel
    ) -> SendDestinationViewModel {
        let tokenItem = walletModel.tokenItem
        let suggestedWallets = builder.makeSuggestedWallets(userWalletModels: userWalletRepository.models)
        let additionalFieldType = SendAdditionalFields.fields(for: tokenItem.blockchain)
        let initial = SendDestinationViewModel.InitialModel(
            networkName: tokenItem.networkName,
            additionalFieldType: additionalFieldType,
            suggestedWallets: suggestedWallets,
            transactionHistoryPublisher: walletModel.transactionHistoryPublisher,
            predefinedDestination: sendType.predefinedDestination,
            predefinedTag: sendType.predefinedTag
        )

        let transactionHistoryMapper = TransactionHistoryMapper(
            currencySymbol: tokenItem.currencySymbol,
            walletAddresses: walletModel.addresses,
            showSign: false
        )

        return SendDestinationViewModel(
            initial: initial,
            input: input,
            output: output,
            processor: makeSendDestinationProcessor(),
            addressTextViewHeightModel: addressTextViewHeightModel,
            transactionHistoryMapper: transactionHistoryMapper
        )
    }

    func makeSendAmountViewModel(
        input: SendAmountInput,
        output: SendAmountOutput,
        validator: SendAmountValidator,
        sendType: SendType
    ) -> SendAmountViewModel {
        let initital = SendAmountViewModel.Settings(
            userWalletName: userWalletModel.name,
            tokenItem: walletModel.tokenItem,
            tokenIconInfo: builder.makeTokenIconInfo(),
            balanceValue: walletModel.balanceValue ?? 0,
            balanceFormatted: walletModel.balance,
            currencyPickerData: builder.makeCurrencyPickerData(),
            predefinedAmount: sendType.predefinedAmount?.value
        )

        let interactor = makeSendAmountInteractor(input: input, output: output, validator: validator)

        return SendAmountViewModel(initial: initital, interactor: interactor)
    }

    func makeSendFeeViewModel(
        router: SendFeeRoutable,
        sendFeeInteractor: SendFeeInteractor,
        notificationManager: SendNotificationManager
    ) -> SendFeeViewModel {
        let feeOptions = builder.makeFeeOptions()
        let initital = SendFeeViewModel.Initial(tokenItem: walletModel.tokenItem, feeOptions: feeOptions)

        return SendFeeViewModel(
            initial: initital,
            router: router,
            interactor: sendFeeInteractor,
            notificationManager: notificationManager
        )
    }

    func makeSendSummaryViewModel(
        sendModel: SendModel,
        notificationManager: SendNotificationManager,
        sendFeeInteractor: SendFeeInteractor,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        walletInfo: SendWalletInfo
    ) -> SendSummaryViewModel {
        let initial = SendSummaryViewModel.Initial(tokenItem: walletModel.tokenItem)

        return SendSummaryViewModel(
            initial: initial,
            input: sendModel,
            notificationManager: notificationManager,
            sendFeeInteractor: sendFeeInteractor,
            addressTextViewHeightModel: addressTextViewHeightModel,
            walletInfo: walletInfo,
            sectionViewModelFactory: makeSendSummarySectionViewModelFactory(walletInfo: walletInfo)
        )
    }

    func makeSendFinishViewModel(
        amount: SendAmount?,
        sendModel: SendModel,
        notificationManager: SendNotificationManager,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        feeTypeAnalyticsParameter: Analytics.ParameterValue,
        walletInfo: SendWalletInfo
    ) -> SendFinishViewModel? {
        let initial = SendFinishViewModel.Initial(tokenItem: walletModel.tokenItem, amount: amount)

        return SendFinishViewModel(
            initial: initial,
            input: sendModel,
            addressTextViewHeightModel: addressTextViewHeightModel,
            feeTypeAnalyticsParameter: feeTypeAnalyticsParameter,
            walletInfo: walletInfo,
            sectionViewModelFactory: makeSendSummarySectionViewModelFactory(walletInfo: walletInfo)
        )
    }

    // MARK: - Dependencies

    private var emailDataProvider: EmailDataProvider {
        return userWalletModel
    }

    private var transactionSigner: TransactionSigner {
        return userWalletModel.signer
    }

    private func makeSendModel(type: SendType, sendFeeInteractor: SendFeeInteractor) -> SendModel {
        let feeIncludedCalculator = FeeIncludedCalculator(validator: walletModel.transactionValidator)

        return SendModel(
            walletModel: walletModel,
            transactionSigner: transactionSigner,
            sendFeeInteractor: sendFeeInteractor,
            feeIncludedCalculator: feeIncludedCalculator,
            sendType: type
        )
    }

    private func makeSendNotificationManager(sendModel: SendModel) -> SendNotificationManager {
        return CommonSendNotificationManager(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            input: sendModel
        )
    }

    func makeSendSummarySectionViewModelFactory(walletInfo: SendWalletInfo) -> SendSummarySectionViewModelFactory {
        SendSummarySectionViewModelFactory(
            feeCurrencySymbol: walletInfo.feeCurrencySymbol,
            feeCurrencyId: walletInfo.feeCurrencyId,
            isFeeApproximate: walletInfo.isFeeApproximate,
            currencyId: walletInfo.currencyId,
            tokenIconInfo: walletInfo.tokenIconInfo
        )
    }

    private func makeSendDestinationProcessor() -> SendDestinationProcessor {
        let tokenItem = walletModel.tokenItem
        let parametersBuilder = SendTransactionParametersBuilder(blockchain: tokenItem.blockchain)

        return CommonSendDestinationProcessor(
            validator: makeSendDestinationValidator(),
            addressResolver: walletModel.addressResolver,
            additionalFieldType: .fields(for: tokenItem.blockchain),
            parametersBuilder: parametersBuilder
        )
    }

    private func makeSendDestinationValidator() -> SendDestinationValidator {
        let addressService = AddressServiceFactory(blockchain: walletModel.wallet.blockchain).makeAddressService()
        let validator = CommonSendDestinationValidator(
            walletAddresses: walletModel.addresses,
            addressService: addressService,
            supportsCompound: walletModel.wallet.blockchain.supportsCompound
        )

        return validator
    }

    private func makeSendAmountValidator() -> SendAmountValidator {
        CommonSendAmountValidator(tokenItem: walletModel.tokenItem, validator: walletModel.transactionValidator)
    }

    private func makeSendAmountInteractor(
        input: SendAmountInput,
        output: SendAmountOutput,
        validator: SendAmountValidator
    ) -> SendAmountInteractor {
        CommonSendAmountInteractor(
            tokenItem: walletModel.tokenItem,
            balanceValue: walletModel.balanceValue ?? 0,
            input: input,
            output: output,
            validator: validator,
            type: .crypto
        )
    }

    func makeSendFeeInteractor(predefinedAmount: Amount?, predefinedDestination: String?) -> SendFeeInteractor {
        let customFeeService = CustomFeeServiceFactory(walletModel: walletModel).makeService()
        let interactor = CommonSendFeeInteractor(
            provider: makeSendFeeProvider(),
            defaultFeeOptions: builder.makeFeeOptions(),
            customFeeService: customFeeService,
            predefinedAmount: predefinedAmount,
            predefinedDestination: predefinedDestination
        )
        customFeeService?.setup(input: interactor, output: interactor)
        return interactor
    }

    func makeSendFeeProvider() -> CommonSendFeeProvider {
        CommonSendFeeProvider(walletModel: walletModel)
    }
}

private extension Blockchain {
    var supportsCompound: Bool {
        switch self {
        case .bitcoin,
             .bitcoinCash,
             .litecoin,
             .dogecoin,
             .dash,
             .kaspa,
             .ravencoin,
             .ducatus:
            return true
        default:
            return false
        }
    }
}
