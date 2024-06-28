//
//  SendTransactionSender.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine

protocol SendTransactionSender {
    var isSending: AnyPublisher<Bool, Never> { get }

    func send(transaction: BlockchainSdk.Transaction) -> AnyPublisher<SendTransactionSentResult, SendTxError>
}

class CommonSendTransactionSender {
    private let walletModel: WalletModel
    private let transactionSigner: TransactionSigner
    private let informationRelevanceService: InformationRelevanceService
    private let emailDataProvider: EmailDataProvider
    private weak var router: SendRoutable?

    private let _isSending = CurrentValueSubject<Bool, Never>(false)

    init(
        walletModel: WalletModel,
        transactionSigner: TransactionSigner,
        informationRelevanceService: InformationRelevanceService,
        emailDataProvider: EmailDataProvider,
        router: SendRoutable
    ) {
        self.walletModel = walletModel
        self.transactionSigner = transactionSigner
        self.informationRelevanceService = informationRelevanceService
        self.emailDataProvider = emailDataProvider
        self.router = router
    }

    private func explorerUrl(from hash: String) -> URL? {
        let factory = ExternalLinkProviderFactory()
        let provider = factory.makeProvider(for: walletModel.blockchainNetwork.blockchain)
        return provider.url(transaction: hash)
    }
}

struct SendTransactionSentResult {
    let url: URL?
}

// MARK: - SendTransactionSender

extension CommonSendTransactionSender: SendTransactionSender {
    var isSending: AnyPublisher<Bool, Never> { _isSending.eraseToAnyPublisher() }

    func send(transaction: BlockchainSdk.Transaction) -> AnyPublisher<SendTransactionSentResult, SendTxError> {
        _isSending.send(true)

        return walletModel
            .send(transaction, signer: transactionSigner)
            .withWeakCaptureOf(self)
            .map { sender, result in
                sender._isSending.send(false)

                return .init(url: sender.explorerUrl(from: result.hash))
            }
            .eraseToAnyPublisher()
    }

    func transactionDidSent() {
        if walletModel.isDemo {
            let alert = AlertBuilder.makeAlert(
                title: "",
                message: Localization.alertDemoFeatureDisabled,
                primaryButton: .default(.init(Localization.commonOk)) { [weak self] in
                    self?.coordinator?.dismiss()
                }
            )

            delegate?.showAlert(alert)
        } else {
            logTransactionAnalytics()
        }
    }
}
