//
//  SendFeeInputOutput.swift
//  Tangem
//
//  Created by Sergey Balashov on 22.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import struct BlockchainSdk.Amount

protocol SendFeeInput: AnyObject {
    var selectedFee: SendFee? { get }

    func selectedFeePublisher() -> AnyPublisher<SendFee?, Never>
    func cryptoAmountPublisher() -> AnyPublisher<Amount, Never>
    func destinationAddressPublisher() -> AnyPublisher<String, Never>
}

protocol SendFeeOutput: AnyObject {
    func feeDidChanged(fee: SendFee)
}
