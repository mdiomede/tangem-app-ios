//
//  SendDestinationInputOutput.swift
//  Tangem
//
//  Created by Sergey Balashov on 25.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SendDestinationInput: AnyObject {
    func destinationPublisher() -> AnyPublisher<SendAddress, Never>
    func additionalFieldPublisher() -> AnyPublisher<DestinationAdditionalFieldType, Never>
}

protocol SendDestinationOutput: AnyObject {
    func destinationDidChanged(_ address: SendAddress?)
    func destinationAdditionalParametersDidChanged(_ type: DestinationAdditionalFieldType)
}
