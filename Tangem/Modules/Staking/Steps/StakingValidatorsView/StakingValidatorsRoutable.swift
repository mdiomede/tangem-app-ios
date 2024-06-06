//
//  StakingValidatorsRoutable.swift
//  Tangem
//
//  Created by Sergey Balashov on 04.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

protocol StakingValidatorsInput: AnyObject {
    func validatorPublisher() -> AnyPublisher<ValidatorType?, Never>
}

protocol StakingValidatorsOutput: AnyObject {
    func userDidSelected(validators: [ValidatorInfo])
}

protocol StakingValidatorsRoutable: AnyObject {
    func userDidSelectedValidator()
}

class StakingValidatorsInputMock: StakingValidatorsInput {
    func validatorPublisher() -> AnyPublisher<ValidatorType?, Never> { .just(output: nil) }
}

class StakingValidatorsOutputMock: StakingValidatorsOutput {
    func userDidSelected(validators: [ValidatorInfo]) {}
}

class StakingValidatorsRoutableMock: StakingValidatorsRoutable {
    func userDidSelectedValidator() {}
}
