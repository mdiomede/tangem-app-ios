//
//  StakingSendAmountValidator.swift
//  Tangem
//
//  Created by Dmitry Fedorov on 08.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine
import TangemStaking

class StakingSendAmountValidator {
    private let tokenItem: TokenItem
    private let validator: TransactionValidator
    private let _stakingManagerState = CurrentValueSubject<StakingManagerState, Never>(.notEnabled)
    private var bag = Set<AnyCancellable>()

    init(
        tokenItem: TokenItem,
        validator: TransactionValidator,
        stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never>
    ) {
        self.tokenItem = tokenItem
        self.validator = validator

        stakingManagerStatePublisher
            .eraseToAnyPublisher()
            .assign(to: \.value, on: _stakingManagerState, ownership: .weak)
            .store(in: &bag)
    }
}

extension StakingSendAmountValidator: SendAmountValidator {
    func validate(amount: Decimal) throws {
        let minAmount: Decimal? = switch _stakingManagerState.value {
        case .availableToStake(let yield): yield.enterMinimumRequirement
        case .staked(_, let yield): yield.exitMinimumRequirement
        default: nil
        }

        if let minAmount, amount < minAmount {
            throw StakingValidationError.amountRequirementError(minAmount: minAmount)
        }

        let amount = Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: amount)
        try validator.validate(amount: amount)
    }
}

enum StakingValidationError: LocalizedError {
    case amountRequirementError(minAmount: Decimal)

    var errorDescription: String? {
        switch self {
        case .amountRequirementError(let minAmount):
            Localization.stakingAmountRequirementError(minAmount)
        }
    }
}
