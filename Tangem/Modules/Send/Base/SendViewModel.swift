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

protocol SendTransactionSender {
    var isSending: AnyPublisher<Bool, Never> { get }

    func send() -> AnyPublisher<URL?, Never>
}

final class SendViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var stepAnimation: SendView.StepAnimation
    @Published var step: any SendStep {
        willSet {
            step.willClose(next: step)
            newValue.willAppear(previous: step)
        } didSet {
            bind(step: step)
        }
    }

    @Published var closeButtonDisabled = false
    @Published var showBackButton = false
    @Published var transactionURL: URL?

    @Published var mainButtonType: SendMainButtonType
    @Published var mainButtonLoading: Bool = false
    @Published var mainButtonDisabled: Bool = false

    @Published var alert: AlertBinder?

    var title: String? { step.title }
    var subtitle: String? { step.subtitle }

    var closeButtonColor: Color {
        closeButtonDisabled ? Colors.Text.disabled : Colors.Text.primary1
    }

    var shouldShowDismissAlert: Bool {
        if case .finish = step.type {
            return false
        }

        return didReachSummaryScreen
    }

//    let sendAmountViewModel: SendAmountViewModel
//    let sendDestinationViewModel: SendDestinationViewModel
//    let sendFeeViewModel: SendFeeViewModel
//    let sendSummaryViewModel: SendSummaryViewModel

//    lazy var sendFinishViewModel: SendFinishViewModel? = factory.makeSendFinishViewModel(
//        sendModel: sendModel,
//        notificationManager: notificationManager,
//        addressTextViewHeightModel: addressTextViewHeightModel,
//        feeTypeAnalyticsParameter: selectedFeeTypeAnalyticsParameter()
//    )

    // MARK: - Dependencies

//    private let initial: Initial
//    private let sendModel: SendModel
//    private let sendType: SendType
//    private let steps: [SendStep]
//    private let walletModel: WalletModel
//    private let userWalletModel: UserWalletModel
//    private let emailDataProvider: EmailDataProvider
//    private let walletInfo: SendWalletInfo
//    private let notificationManager: SendNotificationManager
//    private let addressTextViewHeightModel: AddressTextViewHeightModel
//    private let sendStepParameters: SendStep.Parameters
//    private let keyboardVisibilityService: KeyboardVisibilityService
//    private let factory: SendModulesFactory
    private let interactor: SendBaseInteractor
    private let stepsManager: SendStepsManager
//    private let transactionSender: SendTransactionSender

    private weak var coordinator: SendRoutable?

    private var bag: Set<AnyCancellable> = []
//    private var feeUpdateSubscription: AnyCancellable? = nil

    private var currentPageAnimating: Bool? = nil
    private var didReachSummaryScreen: Bool

    init(
        interactor: SendBaseInteractor,
        stepsManager: SendStepsManager,
        coordinator: SendRoutable
    ) {
//        self.keyboardVisibilityService = keyboardVisibilityService
        self.interactor = interactor
        self.stepsManager = stepsManager
        self.coordinator = coordinator

        step = stepsManager.firstStep
        didReachSummaryScreen = stepsManager.firstStep.type == .summary
        stepAnimation = .moveAndFade

//        mainButtonType = Self.mainButtonType(for: sendType.firstStep, didReachSummaryScreen: didReachSummaryScreen)

        bind()
    }

    func onCurrentPageAppear() {
        if currentPageAnimating != nil {
            currentPageAnimating = true
        }
    }

    func onCurrentPageDisappear() {
        currentPageAnimating = false
    }

    func userDidTapActionButton() {
        switch mainButtonType {
        case .next:
            stepsManager.performNext()
        case .continue:
            stepsManager.performSummary()
        case .send:
            interactor.send()
        case .close:
            coordinator?.dismiss()
        }
    }

    func userDidTapBackButton() {
        stepsManager.performBack()
    }

    func dismiss() {
        Analytics.log(.sendButtonClose, params: [
            .source: step.type.analyticsSourceParameterValue,
            .fromSummary: .affirmativeOrNegative(for: didReachSummaryScreen),
            .valid: .affirmativeOrNegative(for: !mainButtonDisabled),
        ])

        if shouldShowDismissAlert {
            alert = SendAlertBuilder.makeDismissAlert { [coordinator] in
                coordinator?.dismiss()
            }
        } else {
            coordinator?.dismiss()
        }
    }

    func bind(step: any SendStep) {
        didReachSummaryScreen = step.type == .summary

        step.isValidPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.mainButtonDisabled, on: self, ownership: .weak)
            .store(in: &bag)
    }

    func share(url: URL) {
        Analytics.log(.sendButtonShare)
        coordinator?.openShareSheet(url: url)
    }

    func explore(url: URL) {
        Analytics.log(.sendButtonExplore)
        coordinator?.openExplorer(url: url)
    }

//
//    func send() {
//        transactionSender.send()
//            .receiveCompletion { [weak self] completion in
//                switch completion {
//                case .failure(let error):
//                    self?.proceed(sendError: error)
//                case .finished:
//                    self?.transactionDidSent()
//                }
//            }
//            .store(in: &bag)
//    }
//
//    func proceed(sendError error: Error) {
//        Analytics.log(event: .sendErrorTransactionRejected, params: [
//            .token: walletModel.tokenItem.currencySymbol,
//        ])
//
//        if case .noAccount(_, let amount) = (error as? WalletError) {
//            let amountFormatted = Amount(
//                with: walletModel.blockchainNetwork.blockchain,
//                type: walletModel.amountType,
//                value: amount
//            ).string()
//
//            #warning("Use TransactionValidator async validate to get this warning before send tx")
//            let title = Localization.sendNotificationInvalidReserveAmountTitle(amountFormatted)
//            let message = Localization.sendNotificationInvalidReserveAmountText
//
//            alert = AlertBinder(title: title, message: message)
//        } else {
//            let errorCode: String
//            let reason = String(error.localizedDescription.dropTrailingPeriod)
//            if let errorCodeProviding = error as? ErrorCodeProviding {
//                errorCode = "\(errorCodeProviding.errorCode)"
//            } else {
//                errorCode = "-"
//            }
//
//            alert = SendError(
//                title: Localization.sendAlertTransactionFailedTitle,
//                message: Localization.sendAlertTransactionFailedText(reason, errorCode),
//                error: (error as? SendTxError) ?? SendTxError(error: error),
//                openMailAction: openMail
//            )
//            .alertBinder
//        }
//    }
//
//    func transactionDidSent() {
//        stepsManager.performFinish()
//
//        if walletModel.isDemo {
//            let button = Alert.Button.default(Text(Localization.commonOk)) { [weak self] in
//                self?.coordinator?.dismiss()
//            }
//            alert = AlertBuilder.makeAlert(title: "", message: Localization.alertDemoFeatureDisabled, primaryButton: button)
//        } else {
//            logTransactionAnalytics()
//        }
//
//        if let address = sendModel.destination?.value, let token = walletModel.tokenItem.token {
//            UserWalletFinder().addToken(token, in: walletModel.blockchainNetwork.blockchain, for: address)
//        }
//    }

//    func onSummaryAppear() {}
//
//    func onSummaryDisappear() {}

    private func bind() {
        interactor.closeButtonDisabled
            .assign(to: \.closeButtonDisabled, on: self, ownership: .weak)
            .store(in: &bag)

        interactor.isLoading
            .assign(to: \.mainButtonLoading, on: self, ownership: .weak)
            .store(in: &bag)

//        Publishers.CombineLatest(validSteps, $step)
//            .receive(on: DispatchQueue.main)
//            .map { validSteps, step in
//                #warning("TODO: invert the logic and publish INVALID steps instead (?)")
//                switch step {
//                case .finish:
//                    return false
//                default:
//                    return !validSteps.contains(step)
//                }
//            }
//            .assign(to: \.mainButtonDisabled, on: self, ownership: .weak)
//            .store(in: &bag)

        interactor
            .performNext
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, _ in
                viewModel.stepsManager.performNext()
            }
            .store(in: &bag)

//        sendModel
//            .sendError
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] error in
//                guard let self, let error else { return }
//
//                Analytics.log(event: .sendErrorTransactionRejected, params: [
//                    .token: walletModel.tokenItem.currencySymbol,
//                ])
//
//                if case .noAccount(_, let amount) = (error as? WalletError) {
//                    let amountFormatted = Amount(
//                        with: walletModel.blockchainNetwork.blockchain,
//                        type: walletModel.amountType,
//                        value: amount
//                    ).string()
//
//                    #warning("Use TransactionValidator async validate to get this warning before send tx")
//                    let title = Localization.sendNotificationInvalidReserveAmountTitle(amountFormatted)
//                    let message = Localization.sendNotificationInvalidReserveAmountText
//
//                    alert = AlertBinder(title: title, message: message)
//                } else {
//                    let errorCode: String
//                    let reason = String(error.localizedDescription.dropTrailingPeriod)
//                    if let errorCodeProviding = error as? ErrorCodeProviding {
//                        errorCode = "\(errorCodeProviding.errorCode)"
//                    } else {
//                        errorCode = "-"
//                    }
//
//                    alert = SendError(
//                        title: Localization.sendAlertTransactionFailedTitle,
//                        message: Localization.sendAlertTransactionFailedText(reason, errorCode),
//                        error: (error as? SendTxError) ?? SendTxError(error: error),
//                        openMailAction: openMail
//                    )
//                    .alertBinder
//                }
//            }
//            .store(in: &bag)
//
//        sendModel
//            .transactionFinished
//            .removeDuplicates()
//            .sink { [weak self] _ in
//                guard let self else { return }
//
//                stepsManager.performFinish()
//
//                if walletModel.isDemo {
//                    let button = Alert.Button.default(Text(Localization.commonOk)) {
//                        self.coordinator?.dismiss()
//                    }
//                    alert = AlertBuilder.makeAlert(title: "", message: Localization.alertDemoFeatureDisabled, primaryButton: button)
//                } else {
//                    logTransactionAnalytics()
//                }
//
//                if let address = sendModel.destination?.value, let token = walletModel.tokenItem.token {
//                    UserWalletFinder().addToken(token, in: walletModel.blockchainNetwork.blockchain, for: address)
//                }
//            }
//            .store(in: &bag)
    }

//    private func logTransactionAnalytics() {
//        let sourceValue: Analytics.ParameterValue
//        switch sendType {
//        case .send:
//            sourceValue = .transactionSourceSend
//        case .sell:
//            sourceValue = .transactionSourceSell
//        }
//        Analytics.log(event: .transactionSent, params: [
//            .source: sourceValue.rawValue,
//            .token: walletModel.tokenItem.currencySymbol,
//            .blockchain: walletModel.blockchainNetwork.blockchain.displayName,
//            .feeType: selectedFeeTypeAnalyticsParameter().rawValue,
//            .memo: additionalFieldAnalyticsParameter().rawValue,
//        ])
//
//        Analytics.log(.sendSelectedCurrency, params: [
//            .commonType: sendAmountViewModel.amountType.analyticParameter,
//        ])
//    }

//    private func nextStep(after step: SendStep) -> SendStep? {
//        guard
//            let currentStepIndex = steps.firstIndex(of: step),
//            (currentStepIndex + 1) < steps.count
//        else {
//            return nil
//        }
//
//        return steps[currentStepIndex + 1]
//    }

//    private func previousStep(before step: SendStep) -> SendStep? {
//        guard
//            let currentStepIndex = steps.firstIndex(of: step),
//            (currentStepIndex - 1) >= 0
//        else {
//            return nil
//        }
//
//        return steps[currentStepIndex - 1]
//    }

//    private func openMail(with error: SendTxError) {
//        guard let transaction = sendModel.currentTransaction() else { return }
//
//        Analytics.log(.requestSupport, params: [.source: .transactionSourceSend])
//
//        let emailDataCollector = SendScreenDataCollector(
//            userWalletEmailData: emailDataProvider.emailData,
//            walletModel: walletModel,
//            fee: transaction.fee.amount,
//            destination: transaction.destinationAddress,
//            amount: transaction.amount,
//            isFeeIncluded: sendModel.isFeeIncluded,
//            lastError: error
//        )
//        let recipient = emailDataProvider.emailConfig?.recipient ?? EmailConfig.default.recipient
//        coordinator?.openMail(with: emailDataCollector, recipient: recipient)
//    }

//    private func showSummaryStepAlertIfNeeded(_ step: SendStep, stepAnimation: SendView.StepAnimation, checkCustomFee: Bool) -> Bool {
//        if checkCustomFee {
//            let events = notificationManager.notificationInputs.compactMap { $0.settings.event as? SendNotificationEvent }
//            for event in events {
//                switch event {
//                case .customFeeTooLow:
//                    Analytics.log(event: .sendNoticeTransactionDelaysArePossible, params: [
//                        .token: walletModel.tokenItem.currencySymbol,
//                    ])
//
//                    alert = SendAlertBuilder.makeCustomFeeTooLowAlert { [weak self] in
//                        self?.openStep(step, stepAnimation: stepAnimation, checkCustomFee: false, updateFee: false)
//                    }
//
//                    return true
//                case .customFeeTooHigh(let orderOfMagnitude):
//                    alert = SendAlertBuilder.makeCustomFeeTooHighAlert(orderOfMagnitude) { [weak self] in
//                        self?.openStep(step, stepAnimation: stepAnimation, checkCustomFee: false, updateFee: false)
//                    }
//
//                    return true
//                default:
//                    break
//                }
//            }
//        }
//
//        return false
//    }

//    private func mainButtonType(for step: SendStep) -> SendMainButtonType {
//        switch step {
//        case .amount, .destination, .fee:
//            if didReachSummaryScreen {
//                return .continue
//            } else {
//                return .next
//            }
//        case .summary:
//            return .send
//        case .finish:
//            return .close
//        }
//    }

//    private func updateFee() {
//        sendModel.updateFees()
//    }

//    private func shouldCheckCustomFee(currentStep: SendStep) -> Bool {
//        switch currentStep {
//        case .fee:
//            return true
//        default:
//            return false
//        }
//    }

//    private func shouldUpdateFee(currentStep: SendStep, nextStep: SendStep) -> Bool {
//        if nextStep == .summary, currentStep.updateFeeOnLeave {
//            return true
//        } else if nextStep.updateFeeOnOpen {
//            return true
//        } else {
//            return false
//        }
//    }

//    private func openStep(_ step: SendStep, stepAnimation: SendView.StepAnimation, checkCustomFee: Bool = true, updateFee: Bool) {
//        let openStepAfterDelay = { [weak self] in
//            // Slight delay is needed, otherwise the animation of the keyboard will interfere with the page change
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                self?.openStep(step, stepAnimation: stepAnimation, checkCustomFee: checkCustomFee, updateFee: false)
//            }
//        }
//
//        if updateFee {
//            self.updateFee()
//            keyboardVisibilityService.hideKeyboard(completion: openStepAfterDelay)
//            return
//        }
//
//        if keyboardVisibilityService.keyboardVisible, !step.opensKeyboardByDefault {
//            keyboardVisibilityService.hideKeyboard(completion: openStepAfterDelay)
//            return
//        }
//
//        if case .summary = step {
//            if showSummaryStepAlertIfNeeded(step, stepAnimation: stepAnimation, checkCustomFee: checkCustomFee) {
//                return
//            }
//
//            didReachSummaryScreen = true
//
//            sendSummaryViewModel.setupAnimations(previousStep: self.step)
//        }
//
//        // Gotta give some time to update animation variable
//        self.stepAnimation = stepAnimation
//
//        mainButtonType = mainButtonType(for: step)
//
//        DispatchQueue.main.async {
//            self.showBackButton = self.previousStep(before: step) != nil && !self.didReachSummaryScreen
//            self.showTransactionButtons = self.sendModel.transactionURL != nil
//            self.step = step
//            self.transactionDescriptionIsVisisble = step == .summary
//        }
//    }

//    private func openFinishPage() {
//        guard let sendFinishViewModel = sendFinishViewModel else {
//            return
//        }
//
//        openStep(.finish(model: sendFinishViewModel), stepAnimation: .moveAndFade, updateFee: false)
//    }
}

// MARK: - SendModelUIDelegate

extension SendViewModel: SendModelUIDelegate {
    func transactionDidSent() {
        stepsManager.performFinish()
    }

    func showAlert(_ alert: AlertBinder) {
        self.alert = alert
    }
}

// MARK: - SendStepsManagerOutput

extension SendViewModel: SendStepsManagerOutput {
    func update(step: any SendStep, animation: SendView.StepAnimation) {
        stepAnimation = animation
        self.step = step
    }

    func update(mainButtonType: SendMainButtonType) {
        self.mainButtonType = mainButtonType
    }

    func update(backButtonVisible: Bool) {
        showBackButton = backButtonVisible
    }
}

// MARK: - SendStep

private extension SendStepType {
//    var updateFeeOnLeave: Bool {
//        switch self {
//        case .destination, .amount:
//            return true
//        case .fee, .summary, .finish:
//            return false
//        }
//    }

//    var isFinish: Bool {
//        if case .finish = self {
//            return true
//        } else {
//            return false
//        }
//    }

//    var updateFeeOnOpen: Bool {
//        switch self {
//        case .fee:
//            return true
//        case .destination, .amount, .summary, .finish:
//            return false
//        }
//    }

    var analyticsSourceParameterValue: Analytics.ParameterValue {
        switch self {
        case .amount:
            return .amount
        case .destination:
            return .address
        case .fee:
            return .fee
        case .summary:
            return .summary
        case .finish:
            return .finish
        }
    }
}

// MARK: - ValidationError

// private extension ValidationError {
//    var step: SendStep? {
//        switch self {
//        case .invalidAmount, .balanceNotFound:
//            // Shouldn't happen as we validate and cover amount errors separately, synchronously
//            return nil
//        case .amountExceedsBalance,
//             .invalidFee,
//             .feeExceedsBalance,
//             .maximumUTXO,
//             .reserve,
//             .dustAmount,
//             .dustChange,
//             .minimumBalance,
//             .totalExceedsBalance,
//             .cardanoHasTokens,
//             .cardanoInsufficientBalanceToSendToken:
//            return .summary
//        }
//    }
// }

extension SendViewModel {
    struct Initial {
//        let tokenItem: TokenItem
//        let walletName: String
        let feeOptions: [FeeOption]
    }
}

protocol SendStepsManagerInput: AnyObject {
    var currentStep: any SendStep { get }
}

protocol SendStepsManagerOutput: AnyObject {
    func update(step: any SendStep, animation: SendView.StepAnimation)

    func update(mainButtonType: SendMainButtonType)
    func update(backButtonVisible: Bool)
}

protocol SendStepsManager {
    var firstStep: any SendStep { get }

    func performNext()
    func performBack()

    func performSummary()
    func performFinish()

    func setup(input: SendStepsManagerInput, output: SendStepsManagerOutput)
}

class CommonSendStepsManager {
    private let destinationStep: SendDestinationStep
    private let amountStep: SendAmountStep
    private let feeStep: SendFeeStep
    private let summaryStep: SendSummaryStep
    private let finishStep: SendFinishStep

    private weak var input: SendStepsManagerInput?
    private weak var output: SendStepsManagerOutput?

    private var bag: Set<AnyCancellable> = []

    init(
        destinationStep: SendDestinationStep,
        amountStep: SendAmountStep,
        feeStep: SendFeeStep,
        summaryStep: SendSummaryStep,
        finishStep: SendFinishStep
    ) {
        self.destinationStep = destinationStep
        self.amountStep = amountStep
        self.feeStep = feeStep
        self.summaryStep = summaryStep
        self.finishStep = finishStep
    }

    private func getPreviousStep() -> (any SendStep)? {
        switch input?.currentStep.type {
        case .none:
            return destinationStep
        case .destination:
            return amountStep
        case .amount:
            return destinationStep
        case .fee, .summary, .finish:
            assertionFailure("There is no previous step")
            return nil
        }
    }

    private func getNextStep() -> (any SendStep)? {
        switch input?.currentStep.type {
        case .none:
            return destinationStep
        case .destination:
            return amountStep
        case .amount:
            return summaryStep
        case .fee, .summary, .finish:
            assertionFailure("There is no next step")
            return nil
        }
    }

//    private func openStep(_ step: any SendStep, animation: SendView.StepAnimation) {
//        output?.update(animation: animation)
//        output?.update(step: step, animation: animation)
//    }

//    private func openStep(_ step: SendStep, stepAnimation: SendView.StepAnimation, checkCustomFee: Bool = true, updateFee: Bool) {
//        let openStepAfterDelay = { [weak self] in
//            // Slight delay is needed, otherwise the animation of the keyboard will interfere with the page change
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                self?.openStep(step, stepAnimation: stepAnimation, checkCustomFee: checkCustomFee, updateFee: false)
//            }
//        }

//        if updateFee {
//            self.updateFee()
//            keyboardVisibilityService.hideKeyboard(completion: openStepAfterDelay)
//            return
//        }
//
//        if keyboardVisibilityService.keyboardVisible, !step.opensKeyboardByDefault {
//            keyboardVisibilityService.hideKeyboard(completion: openStepAfterDelay)
//            return
//        }

//        if case .summary = step {
//            if showSummaryStepAlertIfNeeded(step, stepAnimation: stepAnimation, checkCustomFee: checkCustomFee) {
//                return
//            }

//            didReachSummaryScreen = true

//            sendSummaryViewModel.setupAnimations(previousStep: self.step)
//        }

    // Gotta give some time to update animation variable
//        self.stepAnimation = stepAnimation

//        mainButtonType = self.mainButtonType(for: step)
//
//        DispatchQueue.main.async {
//            self.showBackButton = self.previousStep(before: step) != nil && !self.didReachSummaryScreen
//            self.showTransactionButtons = self.sendModel.transactionURL != nil
//            self.step = step
//            self.transactionDescriptionIsVisisble = step == .summary
//        }
//    }
}

// TODO: Update fee
// TODO: Update main button
// TODO: Show alert fee

// MARK: - SendStepsManager

extension CommonSendStepsManager: SendStepsManager {
    var firstStep: any SendStep { destinationStep }

    func setup(input: SendStepsManagerInput, output: SendStepsManagerOutput) {
        self.input = input
        self.output = output
    }

    func performBack() {
        guard let previousStep = getPreviousStep() else {
            assertionFailure("Invalid step logic -- back")
            return
        }

        output?.update(step: previousStep, animation: .slideBackward)
    }

    func performNext() {
        guard let input, let next = getNextStep() else {
            return
        }

        func openNext() {
            switch next.type {
            case .destination, .amount, .fee, .finish:
                output?.update(step: next, animation: .slideForward)
                output?.update(mainButtonType: .next)
            case .summary:
                output?.update(step: next, animation: .moveAndFade)
                output?.update(mainButtonType: .send)
            }
        }

        guard input.currentStep.canBeClosed(continueAction: openNext) else {
            return
        }

        openNext()
    }

    func performFinish() {
        output?.update(step: finishStep, animation: .moveAndFade)
    }

    func performSummary() {
        output?.update(step: summaryStep, animation: .moveAndFade)
    }
}

// MARK: - SendSummaryRoutable

extension CommonSendStepsManager: SendSummaryRoutable {
    func openStep(_ step: SendStepType) {
        guard case .summary = input?.currentStep.type else {
            assertionFailure("This code should only be called from summary")
            return
        }

        if let auxiliaryViewAnimatable = auxiliaryViewAnimatable(step) {
            auxiliaryViewAnimatable.setAnimatingAuxiliaryViewsOnAppear()
        }

        switch step {
        case .destination:
            output?.update(step: destinationStep, animation: .moveAndFade)
        case .amount:
            output?.update(step: amountStep, animation: .moveAndFade)
        case .fee:
            output?.update(step: feeStep, animation: .moveAndFade)
        case .summary:
            output?.update(step: summaryStep, animation: .moveAndFade)
        case .finish:
            output?.update(step: finishStep, animation: .moveAndFade)
        }
    }

    private func auxiliaryViewAnimatable(_ step: SendStepType) -> AuxiliaryViewAnimatable? {
        switch step {
        case .destination:
            return destinationStep.viewModel
        case .amount:
            return amountStep.viewModel
        case .fee:
            return feeStep.viewModel
        case .summary:
            return nil
        case .finish:
            return nil
        }
    }
}
