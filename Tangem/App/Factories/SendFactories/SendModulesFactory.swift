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

        let sendAmountInteractor = makeSendAmountInteractor(input: sendModel, output: sendModel, validator:)
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

//        let steps: [SendStep] = [
//            .destination(viewModel: sendDestinationViewModel),
//            .amount(viewModel: sendAmountViewModel),
//            .fee(viewModel: sendFeeViewModel),
//            .summary(viewModel: sendSummaryViewModel),
//        ]

        let viewModel = SendViewModel(
            walletModel: walletModel,
            userWalletModel: <#T##any UserWalletModel#>,
            transactionSigner: <#T##any TransactionSigner#>,
            sendType: <#T##SendType#>,
            emailDataProvider: <#T##any EmailDataProvider#>,
            sendFeeInteractor: <#T##any SendFeeInteractor#>,
            sendAmountValidator: <#T##any SendAmountValidator#>,
            factory: <#T##SendModulesFactory#>,
            stepsManager: <#T##any SendStepsManager#>,
            transactionSender: <#T##any SendTransactionSender#>,
            coordinator: <#T##any SendRoutable#>
        )

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
            coordinator: coordinator
        )
    }

    func makeStepManager(sendType: SendType, router: SendRoutable) -> SendStepsManager {
        let sendAmountInteractor = makeSendAmountInteractor()
        let sendFeeInteractor = makeSendFeeInteractor()
        let informationRelevanceService = makeInformationRelevanceService(sendFeeInteractor: sendFeeInteractor)
        let addressTextViewHeightModel: AddressTextViewHeightModel = .init()

        let sendModel = makeSendModel(
            sendAmountInteractor: sendAmountInteractor,
            sendFeeInteractor: sendFeeInteractor,
            informationRelevanceService: informationRelevanceService,
            type: sendType,
            router: router
        )

        let notificationManager = makeSendNotificationManager(sendModel: sendModel)

        sendAmountInteractor.setup(input: sendModel, output: sendModel)
        sendFeeInteractor.setup(input: sendModel, output: sendModel)

        let destinationStep = makeSendDestinationStep(
            input: sendModel,
            output: sendModel,
            sendFeeInteractor: sendFeeInteractor,
            addressTextViewHeightModel: addressTextViewHeightModel
        )

        let amountStep = makeSendAmountStep(sendAmountInteractor: sendAmountInteractor, sendFeeInteractor: sendFeeInteractor)
        let feeStep = makeFeeSendStep(sendFeeInteractor: sendFeeInteractor, notificationManager: notificationManager, router: router)
        let summaryStep = makeSendSummaryStep(
            interactor: sendModel,
            notificationManager: notificationManager,
            addressTextViewHeightModel: addressTextViewHeightModel,
            sendType: sendType
        )

        summaryStep.viewModel.setup(sendDestinationInput: sendModel)
        summaryStep.viewModel.setup(sendAmountInput: sendModel)
        summaryStep.viewModel.setup(sendFeeInteractor: sendFeeInteractor)

        let finishStep = makeSendFinishStep(
            sendModel: sendModel,
            notificationManager: notificationManager,
            addressTextViewHeightModel: addressTextViewHeightModel
        )

        return CommonSendStepsManager(
            destinationStep: destinationStep,
            amountStep: amountStep,
            feeStep: feeStep,
            summaryStep: summaryStep,
            finishStep: finishStep
        )
    }

    // MARK: - DestinationStep

    func makeSendDestinationStep(
        input: any SendDestinationInput,
        output: any SendDestinationOutput,
        sendFeeInteractor: any SendFeeInteractor,
        addressTextViewHeightModel: AddressTextViewHeightModel
    ) -> SendDestinationStep {
        let sendDestinationInteractor = makeSendDestinationInteractor(input: input, output: output)

        let viewModel = makeSendDestinationViewModel(
            input: input,
            output: output,
//            sendType: <#T##SendType#>,
            addressTextViewHeightModel: addressTextViewHeightModel
        )

        return SendDestinationStep(
            viewModel: viewModel,
            interactor: sendDestinationInteractor,
            sendFeeInteractor: sendFeeInteractor
        )
    }

    func makeSendDestinationViewModel(
        input: SendDestinationInput,
        output: SendDestinationOutput,
//        sendType: SendType,
        addressTextViewHeightModel: AddressTextViewHeightModel
    ) -> SendDestinationViewModel {
        let tokenItem = walletModel.tokenItem
        let suggestedWallets = builder.makeSuggestedWallets(userWalletModels: userWalletRepository.models)
        let additionalFieldType = SendAdditionalFields.fields(for: tokenItem.blockchain)
        let settings = SendDestinationViewModel.Settings(
            networkName: tokenItem.networkName,
            additionalFieldType: additionalFieldType,
            suggestedWallets: suggestedWallets
        )

        let interactor = makeSendDestinationInteractor(input: input, output: output)

        let viewModel = SendDestinationViewModel(
            settings: settings,
            interactor: interactor,
            addressTextViewHeightModel: addressTextViewHeightModel
        )

//        let address = sendType.predefinedDestination.map { SendAddress(value: $0, source: .sellProvider) }
//        viewModel.setExternally(address: address, additionalField: sendType.predefinedTag)

        return viewModel
    }

    // MARK: - AmountStep

    func makeSendAmountStep(
        sendAmountInteractor: any SendAmountInteractor,
        sendFeeInteractor: any SendFeeInteractor
    ) -> SendAmountStep {
        let viewModel = makeSendAmountViewModel(
            interactor: sendAmountInteractor,
            predefinedAmount: nil
        )

        return SendAmountStep(
            viewModel: viewModel,
            interactor: sendAmountInteractor,
            sendFeeInteractor: sendFeeInteractor
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

    // MARK: - FeeStep

    func makeFeeSendStep(
        sendFeeInteractor: any SendFeeInteractor,
        notificationManager: SendNotificationManager,
        router: SendFeeRoutable
    ) -> FeeSendStep {
        let viewModel = makeSendFeeViewModel(
            sendFeeInteractor: sendFeeInteractor,
            notificationManager: notificationManager,
            router: router
        )

        return FeeSendStep(
            viewModel: viewModel,
            interactor: sendFeeInteractor,
            notificationManager: notificationManager,
            tokenItem: walletModel.tokenItem,
            isFixedFee: builder.makeFeeOptions().count == 1
        )
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

    // MARK: - SummaryStep

    func makeSendSummaryStep(
        interactor: SendSummaryInteractor,
        notificationManager: SendNotificationManager,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        sendType: SendType
    ) -> SendSummaryStep {
        let viewModel = makeSendSummaryViewModel(
            interactor: interactor,
            notificationManager: notificationManager,
            addressTextViewHeightModel: addressTextViewHeightModel,
            sendType: sendType
        )

        return SendSummaryStep(
            viewModel: viewModel,
            interactor: interactor,
            tokenItem: walletModel.tokenItem,
            walletName: userWalletModel.name
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

    func makeSendFinishStep(
        sendModel: SendModel,
        notificationManager: SendNotificationManager,
        addressTextViewHeightModel: AddressTextViewHeightModel
    ) -> SendFinishStep {
        let viewModel = makeSendFinishViewModel(
            sendModel: sendModel,
            notificationManager: notificationManager,
            addressTextViewHeightModel: addressTextViewHeightModel,
            feeTypeAnalyticsParameter: <#T##Analytics.ParameterValue#>
        )

        return SendFinishStep(viewModel: <#T##SendFinishViewModel#>, tokenItem: <#T##TokenItem#>)
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
        sendAmountInteractor: SendAmountInteractor,
        sendFeeInteractor: SendFeeInteractor,
        informationRelevanceService: InformationRelevanceService,
        type: SendType,
        router: SendRoutable
    ) -> SendModel {
        let feeIncludedCalculator = FeeIncludedCalculator(validator: walletModel.transactionValidator)

        return SendModel(
            userWalletModel: userWalletModel,
            walletModel: walletModel,
            transactionSigner: transactionSigner,
            sendAmountInteractor: sendAmountInteractor,
            sendFeeInteractor: sendFeeInteractor,
            feeIncludedCalculator: feeIncludedCalculator,
            informationRelevanceService: informationRelevanceService,
            sendType: type,
            coordinator: router
        )
    }

    private func makeSendNotificationManager(sendModel: SendModel) -> SendNotificationManager {
        let manager = CommonSendNotificationManager(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            input: sendModel
        )

        manager.setupManager(with: sendModel)

        return manager
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

    private func makeSendDestinationInteractor(
        input: SendDestinationInput,
        output: SendDestinationOutput
    ) -> SendDestinationInteractor {
        let parametersBuilder = SendTransactionParametersBuilder(blockchain: walletModel.tokenItem.blockchain)

        return CommonSendDestinationInteractor(
            input: input,
            output: output,
            validator: makeSendDestinationValidator(),
            transactionHistoryProvider: makeSendDestinationTransactionHistoryProvider(),
            transactionHistoryMapper: makeTransactionHistoryMapper(),
            addressResolver: walletModel.addressResolver,
            additionalFieldType: .fields(for: walletModel.tokenItem.blockchain),
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

    private func makeSendAmountInteractor() -> SendAmountInteractor {
        CommonSendAmountInteractor(
            tokenItem: walletModel.tokenItem,
            balanceValue: walletModel.balanceValue ?? 0,
            validator: makeSendAmountValidator(),
            type: .crypto
        )
    }

    private func makeSendFeeInteractor() -> SendFeeInteractor { // predefinedAmount: Amount?, predefinedDestination: String?
        let customFeeService = CustomFeeServiceFactory(walletModel: walletModel).makeService()
        let interactor = CommonSendFeeInteractor(
            provider: makeSendFeeProvider(),
            defaultFeeOptions: builder.makeFeeOptions(),
            customFeeService: customFeeService
//            predefinedAmount: predefinedAmount,
//            predefinedDestination: predefinedDestination
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

    private func makeSendDestinationTransactionHistoryProvider() -> SendDestinationTransactionHistoryProvider {
        CommonSendDestinationTransactionHistoryProvider(walletModel: walletModel)
    }

    private func makeTransactionHistoryMapper() -> TransactionHistoryMapper {
        TransactionHistoryMapper(
            currencySymbol: walletModel.tokenItem.currencySymbol,
            walletAddresses: walletModel.addresses,
            showSign: false
        )
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
