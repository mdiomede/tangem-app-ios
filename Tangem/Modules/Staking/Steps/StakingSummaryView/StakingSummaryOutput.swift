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
}

protocol StakingSummaryInput: AnyObject {
    func amountFormattedPublisher() -> AnyPublisher<String?, Never>
    func alternativeAmountFormattedPublisher() -> AnyPublisher<String?, Never>
}

class StakingSummaryOutputMock: StakingSummaryOutput {}

protocol StakingSummaryOutput: AnyObject {}

class StakingSummaryRoutableMock: StakingSummaryRoutable {
    func openAmountStep() {}
}

protocol StakingSummaryRoutable: AnyObject {
    func openAmountStep()
}
