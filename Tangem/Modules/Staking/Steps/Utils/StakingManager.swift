//
//  StakingManager.swift
//  Tangem
//
//  Created by Sergey Balashov on 04.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class StakingManager {
    // MARK: - Dependicies

    private let wallet: WalletModel
    private let converter: CryptoFiatAmountConverter

    // MARK: - Internal

    private let _amount: CurrentValueSubject<CryptoFiatAmount, Never> = .init(.empty)

    private var tokenItem: TokenItem { wallet.tokenItem }
    private let balanceFormatter = BalanceFormatter()

    init(wallet: WalletModel, converter: CryptoFiatAmountConverter) {
        self.wallet = wallet
        self.converter = converter
    }
}

// MARK: - StakingAmountInput, StakingSummaryInput

extension StakingManager: StakingAmountInput, StakingSummaryInput {
    var amount: CryptoFiatAmount {
        _amount.value
    }

    func amountFormattedPublisher() -> AnyPublisher<String?, Never> {
        _amount
            .withWeakCaptureOf(self)
            .map { manager, amount in
                switch amount {
                case .typical(let cachedCrypto, _):
                    manager.balanceFormatter.formatCryptoBalance(cachedCrypto, currencyCode: manager.tokenItem.currencySymbol)
                case .alternative(let cachedFiat, _):
                    manager.balanceFormatter.formatFiatBalance(cachedFiat)
                }
            }
            .eraseToAnyPublisher()
    }

    func alternativeAmountFormattedPublisher() -> AnyPublisher<String?, Never> {
        _amount
            .withWeakCaptureOf(self)
            .map { manager, amount in
                switch amount {
                case .typical(_, let cachedFiat):
                    manager.balanceFormatter.formatFiatBalance(cachedFiat)
                case .alternative(_, let cachedCrypto):
                    manager.balanceFormatter.formatCryptoBalance(cachedCrypto, currencyCode: manager.tokenItem.currencySymbol)
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - StakingAmountOutput

extension StakingManager: StakingAmountOutput {
    func update(amount: CryptoFiatAmount) {
        _amount.send(amount)
    }
}

// MARK: - StakingSummaryOutput

extension StakingManager: StakingSummaryOutput {}
