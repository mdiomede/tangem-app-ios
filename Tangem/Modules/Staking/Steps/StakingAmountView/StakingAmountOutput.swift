//
//  StakingAmountOutput.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class StakingAmountOutputMock: StakingAmountOutput {
    func update(value: Decimal?) {}
}

protocol StakingAmountOutput: AnyObject {
    func update(value: Decimal?)
}

class StakingAmountInputMock: StakingAmountInput {
    func amountPublisher() -> AnyPublisher<Decimal?, Never> {
        .just(output: 1)
    }
}

protocol StakingAmountInput: AnyObject {
    func amountPublisher() -> AnyPublisher<Decimal?, Never>
}
