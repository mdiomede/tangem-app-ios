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
    func amountPublisher() -> AnyPublisher<Decimal?, Never> {
        .just(output: 1)
    }
}

protocol StakingSummaryInput: AnyObject {
    func amountPublisher() -> AnyPublisher<Decimal?, Never>
}

class StakingSummaryOutputMock: StakingSummaryOutput {}

protocol StakingSummaryOutput: AnyObject {}
