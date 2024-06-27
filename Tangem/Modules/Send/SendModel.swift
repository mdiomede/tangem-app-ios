//
//  SendModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BigInt
import BlockchainSdk

protocol SendModelUIDelegate: AnyObject {
    func transactionDidSent()
    func showAlert(_ alert: AlertBinder)
}

class SendModel {
    var destinationValid: AnyPublisher<Bool, Never> {
        _destination.map { $0 != nil }.eraseToAnyPublisher()
    }

    var amountValid: AnyPublisher<Bool, Never> {
        _amount.map { $0 != nil }.eraseToAnyPublisher()
    }

    var feeValid: AnyPublisher<Bool, Never> {
        _selectedFee.map { $0 != nil }.eraseToAnyPublisher()
    }

    var sendError: AnyPublisher<Error?, Never> {
        _sendError.eraseToAnyPublisher()
    }

    var destination: SendAddress? {
        _destination.value
    }

    var destinationAdditionalField: DestinationAdditionalFieldType {
        _destinationAdditionalField.value
    }

    var isFeeIncluded: Bool {
        _isFeeIncluded.value
    }

    var transactionFinished: AnyPublisher<Bool, Never> {
        _transactionTime
            .map { $0 != nil }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var transactionTime: Date? {
        _transactionTime.value
    }

    var transactionURL: URL? {
        _transactionURL.value
    }

    // MARK: - Delegate

    weak var delegate: SendModelUIDelegate?

    // MARK: - Data

    private let _destination: CurrentValueSubject<SendAddress?, Never>
    private let _destinationAdditionalField: CurrentValueSubject<DestinationAdditionalFieldType, Never>
    private let _amount = CurrentValueSubject<SendAmount?, Never>(nil)
    private let _selectedFee = CurrentValueSubject<SendFee?, Never>(nil)
    private let _isFeeIncluded = CurrentValueSubject<Bool, Never>(false)

    private let _transactionCreationError = CurrentValueSubject<Error?, Never>(nil)
    private let _withdrawalNotification = CurrentValueSubject<WithdrawalNotification?, Never>(nil)
    private let transaction = CurrentValueSubject<BlockchainSdk.Transaction?, Never>(nil)

    // MARK: - Raw data

//    private let _isSending = CurrentValueSubject<Bool, Never>(false)
    private let _transactionTime = CurrentValueSubject<Date?, Never>(nil)
    private let _transactionURL = CurrentValueSubject<URL?, Never>(nil)

    private let _sendError = PassthroughSubject<Error?, Never>()

    // MARK: - Private stuff

    private let userWalletModel: UserWalletModel
    private let walletModel: WalletModel
    private let transactionSigner: TransactionSigner
    private let transactionCreator: TransactionCreator
    private let sendAmountInteractor: SendAmountInteractor
    private let sendFeeInteractor: SendFeeInteractor
    private let feeIncludedCalculator: FeeIncludedCalculator
    private let informationRelevanceService: InformationRelevanceService
    private let emailDataProvider: EmailDataProvider
    private let feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder
    private let sendType: SendType
    private weak var coordinator: SendRoutable?

    private var bag: Set<AnyCancellable> = []

    var currencySymbol: String {
        walletModel.tokenItem.currencySymbol
    }

    // MARK: - Public interface

    init(
        userWalletModel: UserWalletModel,
        walletModel: WalletModel,
        transactionCreator: TransactionCreator,
        transactionSigner: TransactionSigner,
        sendAmountInteractor: SendAmountInteractor,
        sendFeeInteractor: SendFeeInteractor,
        feeIncludedCalculator: FeeIncludedCalculator,
        informationRelevanceService: InformationRelevanceService,
        emailDataProvider: EmailDataProvider,
        feeAnalyticsParameterBuilder: FeeAnalyticsParameterBuilder,
        sendType: SendType,
        coordinator: SendRoutable?
    ) {
        self.userWalletModel = userWalletModel
        self.walletModel = walletModel
        self.transactionSigner = transactionSigner
        self.transactionCreator = transactionCreator
        self.sendFeeInteractor = sendFeeInteractor
        self.feeIncludedCalculator = feeIncludedCalculator
        self.sendAmountInteractor = sendAmountInteractor
        self.informationRelevanceService = informationRelevanceService
        self.emailDataProvider = emailDataProvider
        self.feeAnalyticsParameterBuilder = feeAnalyticsParameterBuilder
        self.sendType = sendType
        self.coordinator = coordinator

        let destination = sendType.predefinedDestination.map { SendAddress(value: $0, source: .sellProvider) }
        _destination = .init(destination)

        let fields = SendAdditionalFields.fields(for: walletModel.blockchainNetwork.blockchain)
        let type = fields.map { DestinationAdditionalFieldType.empty(type: $0) } ?? .notSupported
        _destinationAdditionalField = .init(type)

        bind()

        // Update the fees in case we have all prerequisites specified
        if sendType.predefinedAmount != nil, sendType.predefinedDestination != nil {
            updateFees()
        }
    }

    func currentTransaction() -> BlockchainSdk.Transaction? {
        transaction.value
    }

    func updateFees() {
        sendFeeInteractor.updateFees()
    }

    func send() {
        if informationRelevanceService.isActual {
            sendTransaction()
            return
        }

        informationRelevanceService
            .updateInformation()
            .sink { [weak self] completion in
                guard case .failure = completion else {
                    return
                }

                self?.delegate?.showAlert(
                    SendAlertBuilder.makeFeeRetryAlert { self?.send() }
                )

            } receiveValue: { [weak self] result in
                switch result {
                case .feeWasIncreased:
                    self?.delegate?.showAlert(
                        AlertBuilder.makeOkGotItAlert(message: Localization.sendNotificationHighFeeTitle)
                    )
                case .ok:
                    self?.sendTransaction()
                }
            }
            .store(in: &bag)
    }

    func sendTransaction() {
        guard var transaction = transaction.value else {
            AppLog.shared.debug("Transaction object hasn't been created")
            return
        }

        #warning("TODO: loading view")
        #warning("TODO: demo")

        if case .filled(_, _, let params) = _destinationAdditionalField.value {
            transaction.params = params
        }

        _isSending.send(true)
        walletModel.send(transaction, signer: transactionSigner)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }

                _isSending.send(false)

                if case .failure(let error) = completion,
                   !error.toTangemSdkError().isUserCancelled {
                    _sendError.send(error)
                }
            } receiveValue: { [weak self] result in
                guard let self else { return }

                if let transactionURL = explorerUrl(from: result.hash) {
                    _transactionURL.send(transactionURL)
                }
                _transactionTime.send(Date())
            }
            .store(in: &bag)
    }

    private func bind() {
        Publishers
            .CombineLatest3(
                _amount.compactMap { $0?.crypto },
                _destination.compactMap { $0?.value },
                _selectedFee.compactMap { $0?.value.value }
            )
            .removeDuplicates { $0 == $1 }
            .withWeakCaptureOf(self)
            .asyncMap { manager, args throws -> BlockchainSdk.Transaction in
                let (amountValue, destination, fee) = args

                let amount = manager.makeAmount(with: amountValue)
                let includeFee = manager.feeIncludedCalculator.shouldIncludeFee(fee, into: amount)
                manager._isFeeIncluded.send(includeFee)

                let transactionAmount = includeFee ? amount - fee.amount : amount

                let transaction = try await manager.transactionCreator.createTransaction(
                    amount: transactionAmount,
                    fee: fee,
                    destinationAddress: destination
                )

                return transaction
            }
//            .sink { completion in
//                <#code#>
//            } receiveValue: { <#Self.Output#> in
//                <#code#>
//            }

        if let withdrawalValidator = walletModel.withdrawalNotificationProvider {
            transaction
                .map { transaction in
                    guard let transaction else { return nil }
                    return withdrawalValidator.withdrawalNotification(amount: transaction.amount, fee: transaction.fee.amount)
                }
                .sink { [weak self] in
                    self?._withdrawalNotification.send($0)
                }
                .store(in: &bag)
        }
    }

    private func explorerUrl(from hash: String) -> URL? {
        let factory = ExternalLinkProviderFactory()
        let provider = factory.makeProvider(for: walletModel.blockchainNetwork.blockchain)
        return provider.url(transaction: hash)
    }

    private func makeAmount(decimal: Decimal) -> Amount? {
        Amount(with: walletModel.tokenItem.blockchain, type: walletModel.tokenItem.amountType, value: decimal)
    }

    private func openMail(with error: SendTxError) {
        guard let transaction = currentTransaction() else { return }

        Analytics.log(.requestSupport, params: [.source: .transactionSourceSend])

        let emailDataCollector = SendScreenDataCollector(
            userWalletEmailData: emailDataProvider.emailData,
            walletModel: walletModel,
            fee: transaction.fee.amount,
            destination: transaction.destinationAddress,
            amount: transaction.amount,
            isFeeIncluded: isFeeIncluded,
            lastError: error
        )
        let recipient = emailDataProvider.emailConfig?.recipient ?? EmailConfig.default.recipient
        coordinator?.openMail(with: emailDataCollector, recipient: recipient)
    }
}

// MARK: - SendTransactionSender

extension SendModel: SendTransactionSender {
    func send() {
        transactionSender.send()
            .receiveCompletion { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.proceed(sendError: error)
                case .finished:
                    self?.transactionDidSent()
                }
            }
            .store(in: &bag)
    }

    func proceed(sendError error: Error) {
        Analytics.log(event: .sendErrorTransactionRejected, params: [
            .token: walletModel.tokenItem.currencySymbol,
        ])

        if case .noAccount(_, let amount) = (error as? WalletError) {
            let amountFormatted = Amount(
                with: walletModel.blockchainNetwork.blockchain,
                type: walletModel.amountType,
                value: amount
            ).string()

            #warning("Use TransactionValidator async validate to get this warning before send tx")
            let title = Localization.sendNotificationInvalidReserveAmountTitle(amountFormatted)
            let message = Localization.sendNotificationInvalidReserveAmountText

            delegate?.showAlert(AlertBinder(title: title, message: message))
        } else {
            let errorCode: String
            let reason = String(error.localizedDescription.dropTrailingPeriod)
            if let errorCodeProviding = error as? ErrorCodeProviding {
                errorCode = "\(errorCodeProviding.errorCode)"
            } else {
                errorCode = "-"
            }

            let sendError = SendError(
                title: Localization.sendAlertTransactionFailedTitle,
                message: Localization.sendAlertTransactionFailedText(reason, errorCode),
                error: (error as? SendTxError) ?? SendTxError(error: error),
                openMailAction: openMail
            )

            delegate?.showAlert(sendError.alertBinder)
        }
    }

    func transactionDidSent() {
        delegate?.transactionDidSent()

        if walletModel.isDemo {
            let button = Alert.Button.default(Text(Localization.commonOk)) { [weak self] in
                self?.coordinator?.dismiss()
            }

            let alert = AlertBuilder.makeAlert(
                title: "",
                message: Localization.alertDemoFeatureDisabled,
                primaryButton: button
            )

            delegate?.showAlert(alert)
        } else {
            logTransactionAnalytics()
        }

        if let address = destination?.value, let token = walletModel.tokenItem.token {
            UserWalletFinder().addToken(token, in: walletModel.blockchainNetwork.blockchain, for: address)
        }
    }
}

// MARK: - SendDestinationInput

extension SendModel: SendDestinationInput {
    func destinationPublisher() -> AnyPublisher<SendAddress, Never> {
        _destination
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    func additionalFieldPublisher() -> AnyPublisher<DestinationAdditionalFieldType, Never> {
        _destinationAdditionalField.eraseToAnyPublisher()
    }
}

// MARK: - SendDestinationOutput

extension SendModel: SendDestinationOutput {
    func destinationDidChanged(_ address: SendAddress?) {
        _destination.send(address)
    }

    func destinationAdditionalParametersDidChanged(_ type: DestinationAdditionalFieldType) {
        _destinationAdditionalField.send(type)
    }
}

// MARK: - SendAmountInput

extension SendModel: SendAmountInput {
    var amount: SendAmount? { _amount.value }

    func amountPublisher() -> AnyPublisher<SendAmount?, Never> {
        _amount.dropFirst().eraseToAnyPublisher()
    }
}

// MARK: - SendAmountOutput

extension SendModel: SendAmountOutput {
    func amountDidChanged(amount: SendAmount?) {
        _amount.send(amount)
    }
}

// MARK: - SendFeeInput

extension SendModel: SendFeeInput {
    var selectedFee: SendFee? {
        _selectedFee.value
    }

    func selectedFeePublisher() -> AnyPublisher<SendFee?, Never> {
        _selectedFee.eraseToAnyPublisher()
    }

    func cryptoAmountPublisher() -> AnyPublisher<BlockchainSdk.Amount, Never> {
        _amount
            .withWeakCaptureOf(self)
            .compactMap { model, amount in
                amount?.crypto.flatMap { model.makeAmount(decimal: $0) }
            }
            .eraseToAnyPublisher()
    }

    func destinationAddressPublisher() -> AnyPublisher<String, Never> {
        _destination.compactMap { $0?.value }.eraseToAnyPublisher()
    }
}

// MARK: - SendFeeOutput

extension SendModel: SendFeeOutput {
    func feeDidChanged(fee: SendFee) {
        _selectedFee.send(fee)
    }
}

// MARK: - SendSummaryInteractor

extension SendModel: SendSummaryInteractor {
    var isSending: AnyPublisher<Bool, Never> {
        _isSending.eraseToAnyPublisher()
    }
}

// MARK: - SendNotificationManagerInput

extension SendModel: SendNotificationManagerInput {
    // TODO: Refactoring in https://tangem.atlassian.net/browse/IOS-7196
    var selectedSendFeePublisher: AnyPublisher<SendFee?, Never> {
        selectedFeePublisher()
    }

    var feeValues: AnyPublisher<[SendFee], Never> {
        sendFeeInteractor.feesPublisher()
    }

    var isFeeIncludedPublisher: AnyPublisher<Bool, Never> {
        _isFeeIncluded.eraseToAnyPublisher()
    }

    var amountError: AnyPublisher<(any Error)?, Never> {
        .just(output: nil) // TODO: Check it
    }

    var transactionCreationError: AnyPublisher<Error?, Never> {
        _transactionCreationError.eraseToAnyPublisher()
    }

    var withdrawalNotification: AnyPublisher<WithdrawalNotification?, Never> {
        _withdrawalNotification.eraseToAnyPublisher()
    }
}

// MARK: - NotificationTapDelegate

extension SendModel: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId) {}

    func didTapNotificationButton(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .refreshFee:
            updateFees()
        case .openFeeCurrency:
            openNetworkCurrency()
        case .leaveAmount(let amount, _):
            reduceAmountBy(amount, from: walletModel.balanceValue)
        case .reduceAmountBy(let amount, _):
            reduceAmountBy(amount, from: self.amount?.crypto)
        case .reduceAmountTo(let amount, _):
            reduceAmountTo(amount)
        case .generateAddresses,
             .backupCard,
             .buyCrypto,
             .refresh,
             .goToProvider,
             .addHederaTokenAssociation,
             .bookNow,
             .stake,
             .openFeedbackMail,
             .openAppStoreReview:
            assertionFailure("Notification tap not handled")
        }
    }

    private func openNetworkCurrency() {
        guard
            let networkCurrencyWalletModel = userWalletModel.walletModelsManager.walletModels.first(where: {
                $0.tokenItem == walletModel.feeTokenItem && $0.blockchainNetwork == walletModel.blockchainNetwork
            })
        else {
            assertionFailure("Network currency WalletModel not found")
            return
        }

        coordinator?.openFeeCurrency(for: networkCurrencyWalletModel, userWalletModel: userWalletModel)
    }

    private func reduceAmountBy(_ amount: Decimal, from source: Decimal?) {
        guard let source else {
            assertionFailure("WHY")
            return
        }

        var newAmount = source - amount
        if isFeeIncluded, let feeValue = selectedFee?.value.value?.amount.value {
            newAmount = newAmount - feeValue
        }

        _ = sendAmountInteractor.update(amount: newAmount)
//        self._amount.send(SendAmount(type: .typical(crypto: <#T##Decimal?#>, fiat: <#T##Decimal?#>)))
//        sendAmountViewModel.setExternalAmount(newAmount)
    }

    private func reduceAmountTo(_ amount: Decimal) {
        _ = sendAmountInteractor.update(amount: amount)
//        sendAmountViewModel.setExternalAmount(amount)
    }
}

// MARK: - Analytics

private extension SendModel {
    func logTransactionAnalytics() {
        let sourceValue: Analytics.ParameterValue
        switch sendType {
        case .send:
            sourceValue = .transactionSourceSend
        case .sell:
            sourceValue = .transactionSourceSell
        }

        let feeType = feeAnalyticsParameterBuilder.analyticsParameter(selectedFee: selectedFee?.option)

        Analytics.log(event: .transactionSent, params: [
            .source: sourceValue.rawValue,
            .token: walletModel.tokenItem.currencySymbol,
            .blockchain: walletModel.blockchainNetwork.blockchain.displayName,
            .feeType: feeType.rawValue,
            .memo: additionalFieldAnalyticsParameter().rawValue,
        ])

        if let amount {
            Analytics.log(.sendSelectedCurrency, params: [
                .commonType: amount.type.analyticParameter,
            ])
        }
    }

    func additionalFieldAnalyticsParameter() -> Analytics.ParameterValue {
        // If the blockchain doesn't support additional field -- return null
        // Otherwise return full / empty
        switch destinationAdditionalField {
        case .notSupported: .null
        case .empty: .empty
        case .filled: .full
        }
    }
}

extension SendAmount.SendAmountType {
    var analyticParameter: Analytics.ParameterValue {
        switch self {
        case .typical: .token
        case .alternative: .selectedCurrencyApp
        }
    }
}
