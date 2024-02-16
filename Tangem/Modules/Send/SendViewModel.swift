//
//  SendViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import BlockchainSdk
import AVFoundation

final class SendViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var step: SendStep
    @Published var currentStepInvalid: Bool = false
    @Published var alert: AlertBinder?
    @Published var showCameraDeniedAlert = false

    var title: String? {
        step.name
    }

    var showNavigationButtons: Bool {
        step.hasNavigationButtons
    }

    var showBackButton: Bool {
        previousStep != nil
    }

    var showNextButton: Bool {
        nextStep != nil
    }

    var showQRCodeButton: Bool {
        switch step {
        case .destination:
            return true
        case .amount, .fee, .summary, .finish:
            return false
        }
    }

    let sendAmountViewModel: SendAmountViewModel
    let sendDestinationViewModel: SendDestinationViewModel
    let sendFeeViewModel: SendFeeViewModel
    let sendSummaryViewModel: SendSummaryViewModel

    // MARK: - Dependencies

    private var nextStep: SendStep? {
        guard
            let currentStepIndex = steps.firstIndex(of: step),
            (currentStepIndex + 1) < steps.count
        else {
            return nil
        }

        return steps[currentStepIndex + 1]
    }

    private var previousStep: SendStep? {
        guard
            let currentStepIndex = steps.firstIndex(of: step),
            (currentStepIndex - 1) >= 0
        else {
            return nil
        }

        return steps[currentStepIndex - 1]
    }

    private let sendModel: SendModel
    private let sendType: SendType
    private let steps: [SendStep]
    private let walletModel: WalletModel
    private let userWalletModel: UserWalletModel
    private let emailDataProvider: EmailDataProvider
    private let walletInfo: SendWalletInfo
    private let notificationManager: SendNotificationManager

    private weak var coordinator: SendRoutable?

    private var bag: Set<AnyCancellable> = []

    private var currentStepValid: AnyPublisher<Bool, Never> {
        let inputFieldsValid = $step
            .flatMap { [weak self] step -> AnyPublisher<Bool, Never> in
                guard let self else {
                    return .just(output: true)
                }

                switch step {
                case .amount:
                    return sendModel.amountValid
                case .destination:
                    return sendModel.destinationValid
                case .fee:
                    return sendModel.feeValid
                case .summary, .finish:
                    return .just(output: true)
                }
            }

        let hasTransactionCreationError = Publishers.CombineLatest($step, sendModel.transactionCreationError)
            .map { step, errors in
                guard let transactionErrors = errors as? TransactionErrors else { return false }
                return transactionErrors.errors.contains { $0.step == step }
            }

        return Publishers.CombineLatest(inputFieldsValid, hasTransactionCreationError)
            .map { inputFieldsValid, hasTransactionCreationError in
                inputFieldsValid && !hasTransactionCreationError
            }
            .eraseToAnyPublisher()
    }

    init(
        walletName: String,
        walletModel: WalletModel,
        userWalletModel: UserWalletModel,
        transactionSigner: TransactionSigner,
        sendType: SendType,
        emailDataProvider: EmailDataProvider,
        coordinator: SendRoutable
    ) {
        self.coordinator = coordinator
        self.sendType = sendType
        self.walletModel = walletModel
        self.userWalletModel = userWalletModel
        self.emailDataProvider = emailDataProvider

        let addressService = SendAddressServiceFactory(walletModel: walletModel).makeService()
        sendModel = SendModel(walletModel: walletModel, transactionSigner: transactionSigner, addressService: addressService, sendType: sendType)

        let steps = sendType.steps
        guard let firstStep = steps.first else {
            fatalError("No steps provided for the send type")
        }
        self.steps = steps
        step = firstStep

        let tokenIconInfo = TokenIconInfoBuilder().build(from: walletModel.tokenItem, isCustom: walletModel.isCustom)
        let cryptoIconURL: URL?
        if let tokenId = walletModel.tokenItem.id {
            cryptoIconURL = TokenIconURLBuilder().iconURL(id: tokenId)
        } else {
            cryptoIconURL = nil
        }
        walletInfo = SendWalletInfo(
            walletName: walletName,
            balance: Localization.sendWalletBalanceFormat(walletModel.balance, walletModel.fiatBalance),
            blockchain: walletModel.blockchainNetwork.blockchain,
            currencyId: walletModel.tokenItem.currencyId,
            feeCurrencySymbol: walletModel.tokenItem.blockchain.currencySymbol,
            feeCurrencyId: walletModel.tokenItem.blockchain.currencyId,
            isFeeApproximate: walletModel.tokenItem.blockchain.isFeeApproximate(for: walletModel.amountType),
            tokenIconInfo: tokenIconInfo,
            cryptoIconURL: cryptoIconURL,
            cryptoCurrencyCode: walletModel.tokenItem.currencySymbol,
            fiatIconURL: URL(string: "https://vectorflags.s3-us-west-2.amazonaws.com/flags/us-square-01.png")!,
            fiatCurrencyCode: AppSettings.shared.selectedCurrencyCode,
            amountFractionDigits: walletModel.tokenItem.decimalCount,
            feeFractionDigits: walletModel.feeTokenItem.decimalCount,
            feeAmountType: walletModel.feeTokenItem.amountType
        )

        #warning("Fiat icon URL")

        notificationManager = SendNotificationManager(
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            input: sendModel
        )

        sendAmountViewModel = SendAmountViewModel(input: sendModel, walletInfo: walletInfo)
        sendDestinationViewModel = SendDestinationViewModel(input: sendModel)
        sendFeeViewModel = SendFeeViewModel(input: sendModel, notificationManager: notificationManager, walletInfo: walletInfo)
        sendSummaryViewModel = SendSummaryViewModel(input: sendModel, notificationManager: notificationManager, walletInfo: walletInfo)

        sendSummaryViewModel.router = self

        notificationManager.setupManager(with: self)

        bind()
    }

    func next() {
        guard let nextStep else {
            assertionFailure("Invalid step logic -- next")
            return
        }

        step = nextStep
    }

    func back() {
        guard let previousStep else {
            assertionFailure("Invalid step logic -- back")
            return
        }

        step = previousStep
    }

    func scanQRCode() {
        if case .denied = AVCaptureDevice.authorizationStatus(for: .video) {
            showCameraDeniedAlert = true
        } else {
            let binding = Binding<String>(
                get: {
                    ""
                },
                set: { [weak self] in
                    self?.parseQRCode($0)
                }
            )

            let networkName = walletModel.blockchainNetwork.blockchain.displayName
            coordinator?.openQRScanner(with: binding, networkName: networkName)
        }
    }

    private func bind() {
        currentStepValid
            .map {
                !$0
            }
            .assign(to: \.currentStepInvalid, on: self, ownership: .weak)
            .store(in: &bag)

        sendModel
            .isSending
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] isSending in
                self?.setLoadingViewVisibile(isSending)
            }
            .store(in: &bag)

        sendModel
            .sendError
            .compactMap { $0 }
            .sink { [weak self] sendError in
                guard let self else { return }

                alert = SendError(sendError, openMailAction: openMail).alertBinder
            }
            .store(in: &bag)

        sendModel
            .transactionFinished
            .removeDuplicates()
            .sink { [weak self] transactionFinished in
                guard let self, transactionFinished else { return }

                openFinishPage()

                if walletModel.isDemo {
                    let button = Alert.Button.default(Text(Localization.commonOk)) {
                        self.coordinator?.dismiss()
                    }
                    alert = AlertBuilder.makeAlert(title: "", message: Localization.alertDemoFeatureDisabled, primaryButton: button)
                }
            }
            .store(in: &bag)
    }

    private func setLoadingViewVisibile(_ visible: Bool) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if visible {
            appDelegate.addLoadingView()
        } else {
            appDelegate.removeLoadingView()
        }
    }

    private func openMail(with error: Error) {
        guard let transaction = sendModel.currentTransaction() else { return }

        let emailDataCollector = SendScreenDataCollector(
            userWalletEmailData: emailDataProvider.emailData,
            walletModel: walletModel,
            fee: transaction.fee.amount,
            destination: transaction.destinationAddress,
            amount: transaction.amount,
            isFeeIncluded: sendModel.isFeeIncluded,
            lastError: error
        )
        let recipient = emailDataProvider.emailConfig?.recipient ?? EmailConfig.default.recipient
        coordinator?.openMail(with: emailDataCollector, recipient: recipient)
    }

    private func openFinishPage() {
        guard let sendFinishViewModel = SendFinishViewModel(input: sendModel, walletInfo: walletInfo) else {
            assertionFailure("WHY?")
            return
        }

        sendFinishViewModel.router = coordinator
        openStep(.finish(model: sendFinishViewModel))
    }

    private func parseQRCode(_ code: String) {
        #warning("TODO: Add the necessary UI warnings")
        let parser = QRCodeParser(amountType: walletModel.amountType, blockchain: walletModel.blockchainNetwork.blockchain)
        let result = parser.parse(code)

        sendModel.setDestination(result.destination)
        sendModel.setAmount(result.amount)
    }

    // TODO: Andrey Fedorov - Re-use fee currency & redirect logic from Token Details & Send (IOS-5710)
    private func openNetworkCurrency() {
        guard
            let networkCurrencyWalletModel = userWalletModel.walletModelsManager.walletModels.first(where: {
                $0.tokenItem == .blockchain(walletModel.tokenItem.blockchainNetwork) && $0.blockchainNetwork == walletModel.blockchainNetwork
            })
        else {
            assertionFailure("Network currency WalletModel not found")
            return
        }

        coordinator?.presentNetworkCurrency(for: networkCurrencyWalletModel, userWalletModel: userWalletModel)
    }
}

extension SendViewModel: SendSummaryRoutable {
    func openStep(_ step: SendStep) {
        self.step = step
    }

    func send() {
        sendModel.send()
    }
}

extension SendViewModel: NotificationTapDelegate {
    func didTapNotification(with id: NotificationViewId) {}

    func didTapNotificationButton(with id: NotificationViewId, action: NotificationButtonActionType) {
        switch action {
        case .refreshFee:
            sendModel.updateFees()
        case .openFeeCurrency:
            openNetworkCurrency()
        case .reduceBy(let amount, _):
            reduceAmountBy(amount)
        case .reduceTo(let amount, _):
            reduceAmountTo(amount)
        default:
            assertionFailure("Notification tap not handled")
            break
        }
    }

    private func reduceAmountBy(_ amount: Decimal) {
        guard var newAmount = sendModel.amountValue else { return }

        newAmount = newAmount - Amount(with: sendModel.blockchain, type: sendModel.amountType, value: amount)
        if sendModel.isFeeIncluded, let feeValue = sendModel.feeValue?.amount {
            newAmount = newAmount + feeValue
        }

        sendModel.setAmount(newAmount)
    }

    private func reduceAmountTo(_ amount: Decimal) {
        var newAmount = amount

        if sendModel.isFeeIncluded, let feeValue = sendModel.feeValue?.amount.value {
            newAmount = newAmount + feeValue
        }

        sendModel.setAmount(Amount(with: sendModel.blockchain, type: sendModel.amountType, value: newAmount))
    }
}

// MARK: - TransactionError

private extension TransactionError {
    var step: SendStep {
        switch self {
        case .invalidAmount:
            return .amount
        case .amountExceedsBalance, .invalidFee, .feeExceedsBalance, .totalExceedsBalance:
            return .fee
        case .dustAmount, .dustChange, .minimumBalance:
            return .summary
        }
    }
}
