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
        item: StakingTokenItem,
        apy: <#T##Decimal#>,
        rewardRate: <#T##Decimal#>,
        rewardType: <#T##RewardType#>,
        unbonding: <#T##Period#>,
        minimumRequirement: <#T##Decimal#>,
        rewardClaimingType: <#T##RewardClaimingType#>,
        warmupPeriod: <#T##Period#>,
        rewardScheduleType: <#T##RewardScheduleType#>,
        validators: <#T##[ValidatorInfo]#>
    )
}
