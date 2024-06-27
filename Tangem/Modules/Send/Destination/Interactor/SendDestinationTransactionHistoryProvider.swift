//
//  SendDestinationTransactionHistoryProvider.swift
//  Tangem
//
//  Created by Sergey Balashov on 25.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

protocol SendDestinationTransactionHistoryProvider {
    var transactionHistoryPublisher: AnyPublisher<[TransactionRecord], Never> { get }
}

class CommonSendDestinationTransactionHistoryProvider {
    private let walletModel: WalletModel
    private var bag: Set<AnyCancellable> = []

    init(walletModel: WalletModel) {
        self.walletModel = walletModel

        updateTransactionHistoryIfNeeded()
    }

    private func updateTransactionHistoryIfNeeded() {
        walletModel.updateTransactionHistoryIfNeeded()
            .sink()
            .store(in: &bag)
    }
}

extension CommonSendDestinationTransactionHistoryProvider: SendDestinationTransactionHistoryProvider {
    var transactionHistoryPublisher: AnyPublisher<[TransactionRecord], Never> {
        walletModel.transactionHistoryPublisher.map { state in
            guard case .loaded(let items) = state else {
                return []
            }

            return items
        }
        .eraseToAnyPublisher()
    }
}
