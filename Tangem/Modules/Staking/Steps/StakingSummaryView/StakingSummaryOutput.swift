//
//  StakingSummaryOutput.swift
//  Tangem
//
//  Created by Sergey Balashov on 31.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class StakingSummaryInputMock: StakingSummaryInput {
    func amountFormattedPublisher() -> AnyPublisher<String?, Never> { .just(output: "5 SOL") }
    func alternativeAmountFormattedPublisher() -> AnyPublisher<String?, Never> { .just(output: "~ 456.34 $") }
    func validatorPublisher() -> AnyPublisher<StakingManager.ValidatorType?, Never> {
        .just(output: .single(.init(
            address: "123",
            name: "Binance",
            iconURL: URL(string: "ttps://assets.stakek.it/validators/aconcagua.png")!,
            apr: 0.008
        )))
    }
}

protocol StakingSummaryInput: AnyObject {
    func amountFormattedPublisher() -> AnyPublisher<String?, Never>
    func alternativeAmountFormattedPublisher() -> AnyPublisher<String?, Never>
    func validatorPublisher() -> AnyPublisher<StakingManager.ValidatorType?, Never>
}

class StakingSummaryOutputMock: StakingSummaryOutput {}

protocol StakingSummaryOutput: AnyObject {}

class StakingSummaryRoutableMock: StakingSummaryRoutable {
    func openAmountStep() {}
    func openValidatorsStep() {}
}

protocol StakingSummaryRoutable: AnyObject {
    func openAmountStep()
    func openValidatorsStep()
}

class StakingSummaryOutputMock: StakingSummaryOutput {}

protocol StakingSummaryOutput: AnyObject {}

class StakingSummaryRoutableMock: StakingSummaryRoutable {
    func openAmountStep() {}
}

protocol StakingSummaryRoutable: AnyObject {
    func openAmountStep()
}
