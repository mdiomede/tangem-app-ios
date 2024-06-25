//
//  SendDestinationInputOutput.swift
//  Tangem
//
//  Created by Sergey Balashov on 25.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol SendDestinationInput: AnyObject {}

protocol SendDestinationOutput: AnyObject {
    func destinationDidChanged(_ address: SendAddress?)
    func destinationAdditionalParametersDidChanged(_ type: DestinationAdditionalFieldType)
}
