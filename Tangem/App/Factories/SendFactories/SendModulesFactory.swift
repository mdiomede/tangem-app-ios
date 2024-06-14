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

    private var userWalletName: String { userWalletModel.name }
    private var tokenItem: TokenItem { walletModel.tokenItem }

    init(userWalletModel: UserWalletModel, walletModel: WalletModel) {
        self.userWalletModel = userWalletModel
        self.walletModel = walletModel

        builder = .init(userWalletName: userWalletModel.name, walletModel: walletModel)
    }

    // MARK: - Modules

    func makeSendViewModel(type: SendType, coordinator: SendRoutable) -> SendViewModel {
        let sendModel = makeSendModel(type: type)
        let canUseFiatCalculation = quotesRepository.quote(for: walletModel.tokenItem) != nil
        let walletInfo = builder.makeSendWalletInfo(canUseFiatCalculation: canUseFiatCalculation)

        return SendViewModel(
            walletInfo: walletInfo,
            walletModel: walletModel,
            userWalletModel: userWalletModel,
            transactionSigner: transactionSigner,
            sendType: type,
            emailDataProvider: emailDataProvider,
            sendModel: sendModel,
            notificationManager: makeSendNotificationManager(sendModel: sendModel),
            customFeeService: makeCustomFeeService(sendModel: sendModel),
//            fiatCryptoAdapter: makeSendFiatCryptoAdapter(walletInfo: walletInfo),
            keyboardVisibilityService: KeyboardVisibilityService(),
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
        validator: SendAmountValidator
    ) -> SendAmountViewModel {
        let initital = SendAmountViewModel.Initital(
            userWalletName: userWalletName,
            tokenItem: tokenItem,
            tokenIconInfo: builder.makeTokenIconInfo(),
            balanceValue: walletModel.balanceValue ?? 0,
            balanceFormatted: walletModel.balance,
            currencyPickerData: builder.makeCurrencyPickerData()
        )

        return SendAmountViewModel(
            initial: initital,
            input: input,
            output: output,
            validator: validator,
            sendAmountFormatter: makeCryptoFiatAmountFormatter(),
            cryptoFiatAmountConverter: makeCryptoFiatAmountConverter()
        )
    }

    func makeSendFeeViewModel(
        sendModel: SendModel,
        notificationManager: SendNotificationManager,
        customFeeService: CustomFeeService?,
        walletInfo: SendWalletInfo
    ) -> SendFeeViewModel {
        return SendFeeViewModel(
            input: sendModel,
            notificationManager: notificationManager,
            customFeeService: customFeeService,
            walletInfo: walletInfo
        )
    }

    func makeSendSummaryViewModel(
        sendModel: SendModel,
        notificationManager: SendNotificationManager,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        walletInfo: SendWalletInfo
    ) -> SendSummaryViewModel {
        return SendSummaryViewModel(
            input: sendModel,
            notificationManager: notificationManager,
            sendAmountFormatter: makeCryptoFiatAmountFormatter(),
            addressTextViewHeightModel: addressTextViewHeightModel,
            walletInfo: walletInfo,
            sectionViewModelFactory: makeSendSummarySectionViewModelFactory(walletInfo: walletInfo)
        )
    }

    func makeSendFinishViewModel(
        amount: CryptoFiatAmount,
        sendModel: SendModel,
        notificationManager: SendNotificationManager,
        addressTextViewHeightModel: AddressTextViewHeightModel,
        feeTypeAnalyticsParameter: Analytics.ParameterValue,
        walletInfo: SendWalletInfo
    ) -> SendFinishViewModel? {
        let initial = SendFinishViewModel.Initial(amount: amount)

        return SendFinishViewModel(
            initial: initial,
            input: sendModel,
            sendAmountFormatter: makeCryptoFiatAmountFormatter(),
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

    private func makeSendModel(type: SendType) -> SendModel {
        return SendModel(
            walletModel: walletModel,
            transactionSigner: transactionSigner,
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

    private func makeCustomFeeService(sendModel: SendModel) -> CustomFeeService? {
        return CustomFeeServiceFactory(input: sendModel, output: sendModel, walletModel: walletModel).makeService()
    }

//    private func makeSendFiatCryptoAdapter(walletInfo: SendWalletInfo) -> CommonSendFiatCryptoAdapter {
//        CommonSendFiatCryptoAdapter(
//            cryptoCurrencyId: walletInfo.currencyId,
//            currencySymbol: walletInfo.cryptoCurrencyCode,
//            decimals: walletInfo.amountFractionDigits
//        )
//    }

    private func makeSendSummarySectionViewModelFactory(walletInfo: SendWalletInfo) -> SendSummarySectionViewModelFactory {
        return SendSummarySectionViewModelFactory(
            feeCurrencySymbol: walletInfo.feeCurrencySymbol,
            feeCurrencyId: walletInfo.feeCurrencyId,
            isFeeApproximate: walletInfo.isFeeApproximate,
            currencyId: walletInfo.currencyId,
            tokenIconInfo: walletInfo.tokenIconInfo
        )
    }

    private func makeSendDestinationProcessor() -> SendDestinationProcessor {
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

    func makeCryptoFiatAmountFormatter() -> CryptoFiatAmountFormatter {
        CryptoFiatAmountFormatter(currencySymbol: tokenItem.currencySymbol)
    }

    func makeSendAmountValidator() -> SendAmountValidator {
        CommonSendAmountValidator(tokenItem: tokenItem, validator: walletModel.transactionValidator)
    }

    func makeCryptoFiatAmountConverter() -> CryptoFiatAmountConverter { .init(maximumFractionDigits: tokenItem.decimalCount) }
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
