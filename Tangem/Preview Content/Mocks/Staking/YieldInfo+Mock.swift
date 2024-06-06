//
//  YieldInfo+Mock.swift
//  Tangem
//
//  Created by Sergey Balashov on 05.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

extension YieldInfo {
    static let mock = YieldInfo(
        id: "tron-trx-native-staking",
        apy: 0.03712381,
        rewardType: .apr,
        rewardRate: 0.03712381,
        minimumRequirement: 1,
        item: .init(coinId: "tron", contractAdress: nil),
        unbondingPeriod: .days(14),
        warmupPeriod: .days(0),
        rewardClaimingType: .manual,
        rewardScheduleType: .block,
        validators: []
    )
}
