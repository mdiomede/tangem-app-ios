//
//  StakingValidatorsInteractor.swift
//  Tangem
//
//  Created by Sergey Balashov on 10.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemStaking

protocol StakingValidatorsInteractor {
    var validatorsPublisher: AnyPublisher<[ValidatorInfo], Never> { get }
    var selectedValidatorPublisher: AnyPublisher<ValidatorInfo, Never> { get }

    func userDidSelect(validatorAddress: String)
}

class CommonStakingValidatorsInteractor {
    private weak var input: StakingValidatorsInput?
    private weak var output: StakingValidatorsOutput?

    private let tokenItem: TokenItem
    private let stakingRepository: StakingRepository

    private let _validators = CurrentValueSubject<[ValidatorInfo], Never>([])
    private var bag: Set<AnyCancellable> = []

    init(
        input: StakingValidatorsInput,
        output: StakingValidatorsOutput,
        tokenItem: TokenItem,
        stakingRepository: StakingRepository
    ) {
        self.input = input
        self.output = output
        self.tokenItem = tokenItem
        self.stakingRepository = stakingRepository

        bind()
    }
}

// MARK: - Private

private extension CommonStakingValidatorsInteractor {
    func bind() {
        guard let yield = stakingRepository.getYield(item: tokenItem.stakingTokenItem) else {
            AppLog.shared.debug("Yield not found")
            return
        }

        guard !yield.validators.isEmpty else {
            AppLog.shared.debug("Yield.Validators is empty")
            return
        }

        if let defaultValidator = yield.validators.first(where: { $0.address == yield.defaultValidator }) {
            output?.userDidSelected(validator: defaultValidator)
        } else if let first = yield.validators.first {
            output?.userDidSelected(validator: first)
        }

        _validators.send(yield.validators)
    }
}

// MARK: - StakingValidatorsInteractor

extension CommonStakingValidatorsInteractor: StakingValidatorsInteractor {
    var validatorsPublisher: AnyPublisher<[TangemStaking.ValidatorInfo], Never> {
        _validators.eraseToAnyPublisher()
    }

    var selectedValidatorPublisher: AnyPublisher<ValidatorInfo, Never> {
        guard let input else {
            assertionFailure("StakingValidatorsInput is not found")
            return Empty().eraseToAnyPublisher()
        }

        return input.selectedValidatorPublisher
    }

    func userDidSelect(validatorAddress: String) {
        guard let validator = _validators.value.first(where: { $0.address == validatorAddress }) else {
            return
        }

        output?.userDidSelected(validator: validator)
    }
}
