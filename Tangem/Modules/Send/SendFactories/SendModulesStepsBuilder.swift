//
//  SendModulesStepsBuilder.swift
//  Tangem
//
//  Created by Sergey Balashov on 31.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking
import BlockchainSdk

struct SendModulesStepsBuilder {
    private let userWalletName: String
    private let walletModel: WalletModel
    private let userWalletModel: UserWalletModel

    private var tokenItem: TokenItem { walletModel.tokenItem }

    init(userWalletName: String, walletModel: WalletModel, userWalletModel: UserWalletModel) {
        self.userWalletName = userWalletName
        self.walletModel = walletModel
        self.userWalletModel = userWalletModel
    }

    func isFeeApproximate() -> Bool {
        walletModel.tokenItem.blockchain.isFeeApproximate(for: walletModel.amountType)
    }

    func makeTokenIconInfo() -> TokenIconInfo {
        TokenIconInfoBuilder().build(from: walletModel.tokenItem, isCustom: walletModel.isCustom)
    }

    func makeFiatIconURL() -> URL {
        IconURLBuilder().fiatIconURL(currencyCode: AppSettings.shared.selectedCurrencyCode)
    }

    func makeSuggestedWallets(userWalletModels: [UserWalletModel]) -> [SendDestinationViewModel.Settings.SuggestedWallet] {
        userWalletModels.reduce([]) { result, userWalletModel in
            let walletModels = userWalletModel.walletModelsManager.walletModels
            return result + walletModels
                .filter { walletModel in
                    let ignoredAddresses = self.walletModel.wallet.addresses.map { $0.value }

                    return walletModel.blockchainNetwork.blockchain.networkId == self.walletModel.tokenItem.blockchain.networkId &&
                        walletModel.isMainToken &&
                        !ignoredAddresses.contains(walletModel.defaultAddress)
                }
                .map { walletModel in
                    (name: userWalletModel.name, address: walletModel.defaultAddress)
                }
        }
    }

    func makeCurrencyPickerData() -> SendCurrencyPickerData {
        SendCurrencyPickerData(
            cryptoIconURL: makeTokenIconInfo().imageURL,
            cryptoCurrencyCode: tokenItem.currencySymbol,
            fiatIconURL: makeFiatIconURL(),
            fiatCurrencyCode: AppSettings.shared.selectedCurrencyCode,
            disabled: walletModel.quote == nil
        )
    }

    func makeFeeOptions() -> [FeeOption] {
        if walletModel.shouldShowFeeSelector {
            return [.slow, .market, .fast]
        }

        return [.market]
    }

    func makeFeeAnalyticsParameterBuilder() -> FeeAnalyticsParameterBuilder {
        FeeAnalyticsParameterBuilder(isFixedFee: makeFeeOptions().count == 1)
    }

    func makeSendNotificationManager() -> SendNotificationManager {
        CommonSendNotificationManager(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem
        )
    }

    func makeInformationRelevanceService(sendFeeInteractor: SendFeeInteractor) -> InformationRelevanceService {
        CommonInformationRelevanceService(sendFeeInteractor: sendFeeInteractor)
    }

    func makeSendTransactionSummaryDescriptionBuilder() -> SendTransactionSummaryDescriptionBuilder {
        SendTransactionSummaryDescriptionBuilder(tokenItem: walletModel.tokenItem, feeTokenItem: walletModel.feeTokenItem)
    }

    func makeSendTransactionSender() -> SendTransactionSender {
        CommonSendTransactionSender(
            walletModel: walletModel,
            transactionSigner: userWalletModel.signer
        )
    }

    func makeSendModel(
        sendAmountInteractor: SendAmountInteractor,
        sendFeeInteractor: SendFeeInteractor,
        informationRelevanceService: InformationRelevanceService,
        sendTransactionSender: any SendTransactionSender,
        type: SendType,
        router: SendRoutable
    ) -> SendModel {
        let feeIncludedCalculator = FeeIncludedCalculator(validator: walletModel.transactionValidator)

        return SendModel(
            userWalletModel: userWalletModel,
            walletModel: walletModel,
            sendTransactionSender: sendTransactionSender,
            transactionCreator: walletModel.transactionCreator,
            transactionSigner: userWalletModel.signer,
            sendAmountInteractor: sendAmountInteractor,
            sendFeeInteractor: sendFeeInteractor,
            feeIncludedCalculator: feeIncludedCalculator,
            informationRelevanceService: informationRelevanceService,
            emailDataProvider: userWalletModel,
            feeAnalyticsParameterBuilder: makeFeeAnalyticsParameterBuilder(),
            sendType: type,
            coordinator: router
        )
    }
}
