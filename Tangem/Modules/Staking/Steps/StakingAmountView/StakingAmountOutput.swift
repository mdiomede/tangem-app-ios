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
    func update(amount: CryptoFiatAmount) {}
}

protocol StakingAmountOutput: AnyObject {
    func update(amount: CryptoFiatAmount)
}

class StakingAmountInputMock: StakingAmountInput {
    var amount: CryptoFiatAmount { .empty }

    func alternativeAmountFormattedPublisher() -> AnyPublisher<String?, Never> { .just(output: "1") }
}

protocol StakingAmountInput: AnyObject {
    var amount: CryptoFiatAmount { get }
    func alternativeAmountFormattedPublisher() -> AnyPublisher<String?, Never>
}
