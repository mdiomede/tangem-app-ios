//
//  StakeKitMapper.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 27.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct StakeKitMapper {
    // MARK: - Yield

    func mapToYieldInfo(from response: StakeKitDTO.Yield.Info.Response) throws -> YieldInfo {
        guard let enterAction = response.args.enter else {
            throw StakeKitMapperError.noData("EnterAction not found")
        }

        return try YieldInfo(
            id: response.id,
            apy: response.apy,
            rewardType: mapToRewardType(from: response.rewardType),
            rewardRate: response.rewardRate,
            minimumRequirement: enterAction.args.amount.minimum,
            validators: response.validators.compactMap { mapToValidatorInfo(from: $0) },
            defaultValidator: response.metadata.defaultValidator,
            item: mapToStakingTokenItem(from: response.token),
            unbondingPeriod: mapToPeriod(from: response.metadata.cooldownPeriod),
            warmupPeriod: mapToPeriod(from: response.metadata.warmupPeriod),
            rewardClaimingType: mapToRewardClaimingType(from: response.metadata.rewardClaiming),
            rewardScheduleType: mapToRewardScheduleType(from: response.metadata.rewardSchedule)
        )
    }

    // MARK: - Validators

    func mapToValidatorInfo(from validator: StakeKitDTO.Validator) -> ValidatorInfo? {
        guard validator.preferred == true else {
            return nil
        }

        return ValidatorInfo(
            address: validator.address,
            name: validator.name ?? "No name",
            iconURL: validator.image.flatMap { URL(string: $0) },
            apr: validator.apr
        )
    }

    // MARK: - Inner types

    func mapToStakingTokenItem(from token: StakeKitDTO.Token) -> StakingTokenItem {
        StakingTokenItem(coinId: token.coinGeckoId, contractAdress: token.address)
    }

    func mapToRewardType(from rewardType: StakeKitDTO.Yield.Info.Response.RewardType) -> RewardType {
        switch rewardType {
        case .apr: .apr
        case .apy: .apy
        case .variable: .variable
        }
    }

    func mapToPeriod(from period: StakeKitDTO.Yield.Info.Response.Metadata.Period) -> Period {
        .days(period.days)
    }

    func mapToRewardClaimingType(from type: StakeKitDTO.Yield.Info.Response.Metadata.RewardClaiming) -> RewardClaimingType {
        switch type {
        case .auto: .auto
        case .manual: .manual
        }
    }

    func mapToRewardScheduleType(from type: StakeKitDTO.Yield.Info.Response.Metadata.RewardScheduleType) throws -> RewardScheduleType {
        switch type {
        case .block: .block
        case .hour: .hour
        case .day: .day
        case .week: .week
        case .month: .month
        case .era: .era
        case .epoch: .epoch
        }
    }
}

enum StakeKitMapperError: Error {
    case notImplement
    case noData(String)
}
