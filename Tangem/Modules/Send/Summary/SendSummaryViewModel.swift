//
//  SendSummaryViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class SendSummaryViewModel: ObservableObject, Identifiable {
    @Published var editableType: EditableType
    @Published var canEditFee: Bool = false

    @Published var sendDestinationCompactViewModel: SendDestinationCompactViewModel?
    @Published var sendAmountCompactViewModel: SendAmountCompactViewModel?
    @Published var stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?
    @Published var sendFeeCompactViewModel: SendFeeCompactViewModel?

    @Published var destinationVisible = true
    @Published var amountVisible = true
    @Published var validatorVisible = true
    @Published var feeVisible = true {
        didSet {
            print("feeVisible ->>", feeVisible)
        }
    }

    @Published var showHint = false

    @Published var alert: AlertBinder?
    @Published private(set) var notificationInputs: [NotificationViewInput] = []

    @Published var transactionDescription: String?
    @Published var transactionDescriptionIsVisible: Bool = false

    let addressTextViewHeightModel: AddressTextViewHeightModel?

    var canEditAmount: Bool { editableType == .editable }
    var canEditDestination: Bool { editableType == .editable }

    private let tokenItem: TokenItem
    private let interactor: SendSummaryInteractor
    private let notificationManager: NotificationManager
    weak var router: SendSummaryStepsRoutable?

    private var bag: Set<AnyCancellable> = []

    init(
        settings: Settings,
        interactor: SendSummaryInteractor,
        notificationManager: NotificationManager,
        addressTextViewHeightModel: AddressTextViewHeightModel?,
        sendDestinationCompactViewModel: SendDestinationCompactViewModel?,
        sendAmountCompactViewModel: SendAmountCompactViewModel?,
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?,
        sendFeeCompactViewModel: SendFeeCompactViewModel?
    ) {
        editableType = settings.editableType
        tokenItem = settings.tokenItem

        self.interactor = interactor
        self.notificationManager = notificationManager
        self.addressTextViewHeightModel = addressTextViewHeightModel
        self.sendDestinationCompactViewModel = sendDestinationCompactViewModel
        self.sendAmountCompactViewModel = sendAmountCompactViewModel
        self.stakingValidatorsCompactViewModel = stakingValidatorsCompactViewModel
        self.sendFeeCompactViewModel = sendFeeCompactViewModel

        bind()
    }

    func onAppear() {
        destinationVisible = true
        amountVisible = true
        validatorVisible = true
//        feeVisible = true
        transactionDescriptionIsVisible = true

        Analytics.log(.sendConfirmScreenOpened)

        // For the sake of simplicity we're assuming that notifications aren't going to be created after the screen has been displayed
        if notificationInputs.isEmpty, !AppSettings.shared.userDidTapSendScreenSummary {
            withAnimation(SendView.Constants.defaultAnimation.delay(SendView.Constants.animationDuration * 2)) {
                self.showHint = true
            }
        }
    }

    func onDisappear() {}

    func userDidTapDestination() {
        didTapSummary()
        router?.summaryStepRequestEditDestination()
    }

    func userDidTapAmount() {
        didTapSummary()
        router?.summaryStepRequestEditAmount()
    }

    func userDidTapValidator() {
        didTapSummary()
        router?.summaryStepRequestEditValidators()
    }

    func userDidTapFee() {
        didTapSummary()
        router?.summaryStepRequestEditFee()
    }

    private func didTapSummary() {
        AppSettings.shared.userDidTapSendScreenSummary = true
        showHint = false
    }

    private func bind() {
        interactor
            .transactionDescription
            .receive(on: DispatchQueue.main)
            .assign(to: \.transactionDescription, on: self, ownership: .weak)
            .store(in: &bag)

        notificationManager
            .notificationPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, notificationInputs in
                viewModel.notificationInputs = notificationInputs
            }
            .store(in: &bag)
    }
}

// MARK: - SendStepViewAnimatable

extension SendSummaryViewModel: SendStepViewAnimatable {
    func viewDidChangeVisibilityState(_ state: SendStepVisibilityState) {
        guard state.isEditAction else {
            return
        }

        switch state {
        case .appearing(.destination(_), _):
            destinationVisible = false
            amountVisible = true
            validatorVisible = true
            feeVisible = true
        case .appearing(.amount(_), _):
            destinationVisible = true
            amountVisible = false
            validatorVisible = true
            feeVisible = true
        case .appearing(.validators(_), _):
            destinationVisible = true
            amountVisible = true
            validatorVisible = false
//            feeVisible = true
        case .appearing(.fee(_), _):
            destinationVisible = true
            amountVisible = true
            validatorVisible = true
            feeVisible = false
        case .appeared, .disappeared, .disappearing:
            break
        default:
            assertionFailure("Not implemented")
        }

        showHint = false
        transactionDescriptionIsVisible = false
    }
}

/*
 func setup(sendFeeInput input: SendFeeInput) {
     input
         .feesPublisher
         .map { feeValues in
             let multipleFeeOptions = feeValues.count > 1
             let hasError = feeValues.contains { $0.value.error != nil }

             return multipleFeeOptions && !hasError
         }
         .receive(on: DispatchQueue.main)
         .assign(to: \.canEditFee, on: self, ownership: .weak)
         .store(in: &bag)
 */

extension SendSummaryViewModel {
    struct Settings {
        let tokenItem: TokenItem
        let editableType: EditableType
    }

    enum EditableType: Hashable {
        case disable
        case editable
    }
}
