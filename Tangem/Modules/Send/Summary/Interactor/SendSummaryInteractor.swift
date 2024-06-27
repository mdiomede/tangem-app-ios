//
//  SendSummaryInteractor.swift
//  Tangem
//
//  Created by Sergey Balashov on 24.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SendSummaryInput: AnyObject {}

protocol SendSummaryOutput: AnyObject {}

protocol SendSummaryInteractor: AnyObject {
    var isSending: AnyPublisher<Bool, Never> { get }
    var transactionDescription: AnyPublisher<String?, Never> { get }
}

class CommonSendSummaryInteractor {
    private let sendTransactionSender: SendTransactionSender
    private let sendAmountInput: SendAmountInput
    private let sendFeeInput: SendFeeInput
    private let descriptionBuilder: SendTransactionSummaryDescriptionBuilder

    init(
        sendTransactionSender: SendTransactionSender,
        sendAmountInput: SendAmountInput,
        sendFeeInput: SendFeeInput,
        descriptionBuilder: SendTransactionSummaryDescriptionBuilder
    ) {
        self.sendTransactionSender = sendTransactionSender
        self.sendAmountInput = sendAmountInput
        self.sendFeeInput = sendFeeInput
        self.descriptionBuilder = descriptionBuilder
    }
}

extension CommonSendSummaryInteractor: SendSummaryInteractor {
    var isSending: AnyPublisher<Bool, Never> {
        sendTransactionSender.isSending
    }

    var transactionDescription: AnyPublisher<String?, Never> {
        Publishers
            .CombineLatest(
                sendAmountInput.amountPublisher().compactMap { $0 },
                sendFeeInput.selectedFeePublisher().compactMap { $0?.value.value?.amount.value }
            )
            .withWeakCaptureOf(self)
            .map {
                $0.descriptionBuilder.makeDescription(amount: $1.0, fee: $1.1)
            }
            .eraseToAnyPublisher()
    }
}
