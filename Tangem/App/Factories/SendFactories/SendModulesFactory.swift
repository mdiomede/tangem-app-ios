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

        let informationRelevanceService = makeInformationRelevanceService(sendFeeInteractor: sendFeeInteractor)

        let sendModel = makeSendModel(
            sendFeeInteractor: sendFeeInteractor,
            informationRelevanceService: informationRelevanceService,
            type: type
        )
        let canUseFiatCalculation = quotesRepository.quote(for: walletModel.tokenItem) != nil
        let walletInfo = builder.makeSendWalletInfo(canUseFiatCalculation: canUseFiatCalculation)
        let initial = SendViewModel.Initial(feeOptions: builder.makeFeeOptions())
        sendFeeInteractor.setup(input: sendModel, output: sendModel)

        let notificationManager = makeSendNotificationManager(sendModel: sendModel)

        let addressTextViewHeightModel: AddressTextViewHeightModel = .init()
        let sendDestinationViewModel = makeSendDestinationViewModel(
            input: sendModel,
            output: sendModel,
            sendType: type,
            addressTextViewHeightModel: addressTextViewHeightModel
        )

        let sendAmountInteractor = makeSendAmountInteractor(input: sendModel, output: sendModel, validator: makeSendAmountValidator())
        let sendAmountViewModel = makeSendAmountViewModel(
            interactor: sendAmountInteractor,
            predefinedAmount: type.predefinedAmount?.value
        )

        let sendFeeViewModel = makeSendFeeViewModel(
            sendFeeInteractor: sendFeeInteractor,
            notificationManager: notificationManager,
            router: coordinator
        )

        let sendSummaryViewModel = makeSendSummaryViewModel(
            interactor: sendModel,
            notificationManager: notificationManager,
            addressTextViewHeightModel: addressTextViewHeightModel,
            sendType: type
        )

        sendSummaryViewModel.setup(sendDestinationInput: sendModel)
        sendSummaryViewModel.setup(sendAmountInput: sendModel)
        sendSummaryViewModel.setup(sendFeeInteractor: sendFeeInteractor)

        let steps: [SendStep] = [
            .destination(viewModel: sendDestinationViewModel, step: sendDestinationViewModel),
            .amount(viewModel: sendAmountViewModel, step: sendAmountInteractor),
            .fee(viewModel: sendFeeViewModel, step: sendFeeInteractor),
            .summary(viewModel: sendSummaryViewModel)
        ]

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
        interactor: SendAmountInteractor,
        predefinedAmount: Decimal?
    ) -> SendAmountViewModel {
        let initital = SendAmountViewModel.Settings(
            userWalletName: userWalletModel.name,
            tokenItem: walletModel.tokenItem,
            tokenIconInfo: builder.makeTokenIconInfo(),
            balanceValue: walletModel.balanceValue ?? 0,
            balanceFormatted: walletModel.balance,
            currencyPickerData: builder.makeCurrencyPickerData(),
            predefinedAmount: predefinedAmount
        )

        return SendAmountViewModel(initial: initital, interactor: interactor)
    }

    func makeSendFeeViewModel(
        sendFeeInteractor: SendFeeInteractor,
        notificationManager: SendNotificationManager,
        router: SendFeeRoutable
    ) -> SendFeeViewModel {
        let initital = SendFeeViewModel.Initial(tokenItem: walletModel.tokenItem)

        return SendFeeViewModel(
            initial: initital,
            interactor: sendFeeInteractor,
            notificationManager: notificationManager,
            router: router
        )
    }

    func makeSendSummaryViewModel(
        interactor: SendSummaryInteractor,
        notificationManager: SendNotificationManager,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        sendType: SendType
    ) -> SendSummaryViewModel {
        let initial = SendSummaryViewModel.Initial(
            tokenItem: walletModel.tokenItem,
            canEditAmount: sendType.predefinedAmount == nil,
            canEditDestination: sendType.predefinedDestination == nil
        )

        return SendSummaryViewModel(
            initial: initial,
            interactor: interactor,
            notificationManager: notificationManager,
            addressTextViewHeightModel: addressTextViewHeightModel,
            sectionViewModelFactory: makeSendSummarySectionViewModelFactory()
        )
    }

    func makeSendFinishViewModel(
        sendModel: SendModel,
        notificationManager: SendNotificationManager,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        feeTypeAnalyticsParameter: Analytics.ParameterValue
    ) -> SendFinishViewModel? {
        guard let destinationText = sendModel.destination?.value,
              let amount = sendModel.amount,
              let feeValue = sendModel.selectedFee,
              let transactionTime = sendModel.transactionTime else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        let transactionTimeFormatted = formatter.string(from: transactionTime)

        let initial = SendFinishViewModel.Initial(
            tokenItem: walletModel.tokenItem,
            destination: destinationText,
            additionalField: sendModel.destinationAdditionalField,
            amount: amount,
            feeValue: feeValue,
            transactionTimeFormatted: transactionTimeFormatted
        )

        return SendFinishViewModel(
            initial: initial,
            addressTextViewHeightModel: addressTextViewHeightModel,
            feeTypeAnalyticsParameter: feeTypeAnalyticsParameter,
            sectionViewModelFactory: makeSendSummarySectionViewModelFactory()
        )
    }

    // MARK: - Dependencies

    private var emailDataProvider: EmailDataProvider {
        return userWalletModel
    }

    private var transactionSigner: TransactionSigner {
        return userWalletModel.signer
    }

    private func makeSendModel(
        sendFeeInteractor: SendFeeInteractor,
        informationRelevanceService: InformationRelevanceService,
        type: SendType
    ) -> SendModel {
        let feeIncludedCalculator = FeeIncludedCalculator(validator: walletModel.transactionValidator)

        return SendModel(
            walletModel: walletModel,
            transactionSigner: transactionSigner,
            sendFeeInteractor: sendFeeInteractor,
            feeIncludedCalculator: feeIncludedCalculator,
            informationRelevanceService: informationRelevanceService,
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

    func makeSendSummarySectionViewModelFactory() -> SendSummarySectionViewModelFactory {
        return SendSummarySectionViewModelFactory(
            feeCurrencySymbol: walletModel.feeTokenItem.currencySymbol,
            feeCurrencyId: walletModel.feeTokenItem.currencyId,
            isFeeApproximate: builder.isFeeApproximate(),
            currencyId: walletModel.tokenItem.currencyId,
            tokenIconInfo: builder.makeTokenIconInfo()
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

    private func makeSendFeeInteractor(predefinedAmount: Amount?, predefinedDestination: String?) -> SendFeeInteractor {
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

    private func makeSendFeeProvider() -> CommonSendFeeProvider {
        CommonSendFeeProvider(walletModel: walletModel)
    }

    private func makeInformationRelevanceService(sendFeeInteractor: SendFeeInteractor) -> InformationRelevanceService {
        CommonInformationRelevanceService(sendFeeInteractor: sendFeeInteractor)
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
