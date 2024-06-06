//
//  StakingManager.swift
//  Tangem
//
//  Created by Sergey Balashov on 04.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

class StakingManager {
    // MARK: - Dependicies

    private let wallet: WalletModel
    private let yield: YieldInfo
    private let converter: CryptoFiatAmountConverter

    // MARK: - Internal

    private let _amount: CurrentValueSubject<CryptoFiatAmount, Never> = .init(.empty)
    private let _validator: CurrentValueSubject<ValidatorType?, Never> = .init(nil)

    private var tokenItem: TokenItem { wallet.tokenItem }
    private let balanceFormatter = BalanceFormatter()

    init(
        wallet: WalletModel,
        yield: YieldInfo,
        converter: CryptoFiatAmountConverter
    ) {
        self.wallet = wallet
        self.yield = yield
        self.converter = converter

        _validator.send(yield.validators.first.map { .single($0) })
    }
}

// MARK: - StakingAmountInput, StakingSummaryInput, StakingValidatorsInput

extension StakingManager: StakingAmountInput, StakingSummaryInput, StakingValidatorsInput {
    var amount: CryptoFiatAmount {
        _amount.value
    }

    func amountFormattedPublisher() -> AnyPublisher<String?, Never> {
        _amount
            .withWeakCaptureOf(self)
            .map { manager, amount in
                switch amount {
                case .empty:
                    return nil
                case .typical(let cachedCrypto, _):
                    return manager.balanceFormatter.formatCryptoBalance(cachedCrypto, currencyCode: manager.tokenItem.currencySymbol)
                case .alternative(let cachedFiat, _):
                    return manager.balanceFormatter.formatFiatBalance(cachedFiat)
                }
            }
            .eraseToAnyPublisher()
    }

    func alternativeAmountFormattedPublisher() -> AnyPublisher<String?, Never> {
        _amount
            .withWeakCaptureOf(self)
            .map { manager, amount in
                switch amount {
                case .empty:
                    return nil
                case .typical(_, let cachedFiat):
                    return manager.balanceFormatter.formatFiatBalance(cachedFiat)
                case .alternative(_, let cachedCrypto):
                    return manager.balanceFormatter.formatCryptoBalance(cachedCrypto, currencyCode: manager.tokenItem.currencySymbol)
                }
            }
            .eraseToAnyPublisher()
    }

    func validatorPublisher() -> AnyPublisher<ValidatorType?, Never> {
        _validator.eraseToAnyPublisher()
    }
}

// MARK: - StakingAmountOutput

extension StakingManager: StakingAmountOutput {
    func update(amount: CryptoFiatAmount) {
        _amount.send(amount)
    }
}

// MARK: - StakingValidatorsOutput

extension StakingManager: StakingValidatorsOutput {
    func userDidSelected(validators: [ValidatorInfo]) {}
}

// MARK: - StakingSummaryOutput

extension StakingManager: StakingSummaryOutput {}

extension StakingManager {
    enum ValidatorType: Hashable {
        case single(ValidatorInfo)
        case multiple([ValidatorInfo])
    }
}
