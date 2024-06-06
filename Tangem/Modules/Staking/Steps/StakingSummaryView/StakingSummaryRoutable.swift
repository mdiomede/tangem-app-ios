//
//  StakingSummaryRoutable.swift
//  Tangem
//
//  Created by Sergey Balashov on 06.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class StakingSummaryRoutableMock: StakingSummaryRoutable {
    func openAmountStep() {}
    func openValidatorsStep() {}
}

protocol StakingSummaryRoutable: AnyObject {
    func openAmountStep()
    func openValidatorsStep()
}
