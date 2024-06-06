//
//  StakingValidatorsInput.swift
//  Tangem
//
//  Created by Sergey Balashov on 06.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol StakingValidatorsInput: AnyObject {
    func validatorPublisher() -> AnyPublisher<StakingManager.ValidatorType?, Never>
}

class StakingValidatorsInputMock: StakingValidatorsInput {
    func validatorPublisher() -> AnyPublisher<StakingManager.ValidatorType?, Never> { .just(output: nil) }
}
