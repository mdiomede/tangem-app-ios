//
//  StakingFeeInteractor.swift
//  Tangem
//
//  Created by Sergey Balashov on 10.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemStaking

class StakingFeeInteractor {
    private weak var input: SendFeeInput?
    private weak var output: SendFeeOutput?
    private let manager: StakingManager

    private let _fee: CurrentValueSubject<LoadingValue<Fee>, Never> = .init(.loading)

    private var bag: Set<AnyCancellable> = []

    init(input: SendFeeInput, output: SendFeeOutput, manager: StakingManager) {
        self.input = input
        self.output = output
        self.manager = manager

        bind()
    }

    func bind() {
        _fee
            .withWeakCaptureOf(self)
            .compactMap { interactor, fee in
                interactor.mapToSendFee(fee: fee)
            }
            // Only once
            .first()
            .withWeakCaptureOf(self)
            .sink { interactor, fee in
                interactor.initialSelectedFeeUpdateIfNeeded(fee: fee)
            }
            .store(in: &bag)
    }
}

// MARK: - SendFeeInteractor

extension StakingFeeInteractor: SendFeeInteractor {
    var selectedFee: SendFee? {
        input?.selectedFee
    }

    var selectedFeePublisher: AnyPublisher<SendFee, Never> {
        guard let input else {
            assertionFailure("SendFeeInput is not found")
            return Empty().eraseToAnyPublisher()
        }

        return input.selectedFeePublisher
    }

    var feesPublisher: AnyPublisher<[SendFee], Never> {
        _fee.map { fee in
            [SendFee(option: .market, value: fee)]
        }
        .eraseToAnyPublisher()
    }

    var customFeeInputFieldModels: [SendCustomFeeInputFieldModel] { [] }

    func updateFees() {
//        manager.getFee(amount: <#T##Decimal#>, validator: <#T##String#>)
    }

    func update(selectedFee: SendFee) {
        output?.feeDidChanged(fee: selectedFee)
    }
}

// MARK: - Private

private extension StakingFeeInteractor {
    func mapToSendFee(fee: LoadingValue<Fee>) -> SendFee {
        SendFee(option: .market, value: fee)
    }

    private func initialSelectedFeeUpdateIfNeeded(fee: SendFee) {
        guard input?.selectedFee == nil else {
            return
        }

        output?.feeDidChanged(fee: fee)
    }
}
