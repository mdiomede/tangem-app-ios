//
//  SendBaseInteractor.swift
//  Tangem
//
//  Created by Sergey Balashov on 27.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SendBaseInteractor {
    var isLoading: AnyPublisher<Bool, Never> { get }
    var performNext: AnyPublisher<Void, Never> { get }
//    var mainButtonType: AnyPublisher<SendMainButtonType, Never> { get }

    var closeButtonDisabled: AnyPublisher<Bool, Never> { get }
    var mainButtonDisabled: AnyPublisher<Bool, Never> { get }

    var transactionDidSent: AnyPublisher<URL?, Never> { get }

    func send()
}

class CommonSendBaseInteractor {
    private let sendTransactionSender: SendTransactionSender
    private let sendDestinationInput: SendDestinationInput

    init(
        sendTransactionSender: SendTransactionSender,
        sendDestinationInput: SendDestinationInput,
        sendAmountInput: SendAmountInput,
        sendFeeInput: SendFeeInput,
        summaryDestinationHelper: SendTransactionSummaryDescriptionBuilder
    ) {
        self.sendTransactionSender = sendTransactionSender
        self.sendDestinationInput = sendDestinationInput
    }
}

extension CommonSendBaseInteractor: SendBaseInteractor {
    var isLoading: AnyPublisher<Bool, Never> {
        sendTransactionSender.isSending
    }

    var performNext: AnyPublisher<Void, Never> {
        sendDestinationInput
            .destinationPublisher()
            .filter { destination in
                switch destination.source {
                case .myWallet, .recentAddress:
                    return true
                default:
                    return false
                }
            }
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    var closeButtonDisabled: AnyPublisher<Bool, Never> {
        sendTransactionSender.isSending.eraseToAnyPublisher()
    }

    var mainButtonDisabled: AnyPublisher<Bool, Never> {
        sendTransactionSender.isSending.eraseToAnyPublisher()
    }

    var transactionDidSent: AnyPublisher<URL?, Never> {}

    func send() {
        sendTransactionSender.send()
    }
}
