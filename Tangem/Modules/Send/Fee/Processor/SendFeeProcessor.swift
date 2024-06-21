//
//  SendFeeInteractor.swift
//  Tangem
//
//  Created by Sergey Balashov on 18.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

protocol SendFeeInteractorInput: AnyObject {
    var cryptoAmountPublisher: AnyPublisher<Amount, Never> { get }
    var destinationPublisher: AnyPublisher<String, Never> { get }
}

protocol SendFeeInteractor {
    func updateFees()

    func feesPublisher() -> AnyPublisher<[SendFee], Never>

    func customFeePublisher() -> AnyPublisher<SendFee, Never>
    func customFeeInputFieldModels() -> [SendCustomFeeInputFieldModel]

    func setup(input: SendFeeInteractorInput)
}
