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
    private let _minimumAmount = CurrentValueSubject<Decimal?, Never>(.none)
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
            .compactMap { state in
                switch state {
                case .availableToStake(let yield): yield.enterMinimumRequirement
                case .staked(_, let yield): yield.exitMinimumRequirement
                default: nil
                }
            }
            .assign(to: \.value, on: _minimumAmount, ownership: .weak)
            .store(in: &bag)
    }
}

extension StakingSendAmountValidator: SendAmountValidator {
    func validate(amount: Decimal) throws {
        if let minAmount = _minimumAmount.value, amount < minAmount {
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
