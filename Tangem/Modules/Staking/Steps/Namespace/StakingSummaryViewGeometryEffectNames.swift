//
//  StakingSummaryViewGeometryEffectNames.swift
//  Tangem
//
//  Created by Sergey Balashov on 31.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - All names

struct StakingViewNamespaceID: StakingAmountViewGeometryEffectNames,
                                StakingSummaryViewGeometryEffectNames {
    var amountContainer: String { "amountContainer" }
    var tokenIcon: String { "tokenIcon" }
    var amountCryptoText: String { "amountCryptoText" }
    var amountFiatText: String { "amountFiatText" }
}

// MARK: - Amount section

protocol StakingAmountViewGeometryEffectNames {
    var amountContainer: String { get }
    var tokenIcon: String { get }
    var amountCryptoText: String { get }
    var amountFiatText: String { get }
}

// MARK: - Summary section

protocol StakingSummaryViewGeometryEffectNames {
    var amountContainer: String { get }
    var tokenIcon: String { get }
    var amountCryptoText: String { get }
    var amountFiatText: String { get }
}
