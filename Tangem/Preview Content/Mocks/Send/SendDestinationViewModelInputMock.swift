//
//  SendSendDestinationInputMock.swift
//  Tangem
//
//  Created by Andrey Chukavin on 01.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import BlockchainSdk

class SendDestinationInputOutputMock: SendDestinationInput, SendDestinationOutput {
    func destinationTextPublisher() -> AnyPublisher<String, Never> {
        .just(output: "0x123123")
    }

    func additionalFieldPublisher() -> AnyPublisher<DestinationAdditionalFieldType, Never> {
        .just(output: .empty(type: .memo))
    }

    func destinationDidChanged(_ address: SendAddress?) {}

    func destinationAdditionalParametersDidChanged(_ type: DestinationAdditionalFieldType) {}
}
