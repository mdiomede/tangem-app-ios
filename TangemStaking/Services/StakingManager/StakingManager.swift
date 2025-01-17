//
//  StakingManager.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 28.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public protocol StakingManager {
    var state: StakingManagerState { get }
    var statePublisher: AnyPublisher<StakingManagerState, Never> { get }

    func updateState() async throws
    func estimateFee(action: StakingAction) async throws -> Decimal
    func transaction(action: StakingAction) async throws -> StakingTransactionInfo
}

public enum StakingManagerState: Hashable, CustomStringConvertible {
    case loading
    case notEnabled
    // When we turn off the YieldInfo in the admin panel
    case temporaryUnavailable(YieldInfo)
    case availableToStake(YieldInfo)
    case staked(Staked)

    public var isAvailable: Bool {
        switch self {
        case .loading, .notEnabled, .temporaryUnavailable:
            return false
        case .availableToStake, .staked:
            return true
        }
    }

    public var isStaked: Bool {
        switch self {
        case .staked: true
        default: false
        }
    }

    public var yieldInfo: YieldInfo? {
        switch self {
        case .loading, .notEnabled:
            return nil
        case .temporaryUnavailable(let yieldInfo), .availableToStake(let yieldInfo):
            return yieldInfo
        case .staked(let staked):
            return staked.yieldInfo
        }
    }

    public var description: String {
        switch self {
        case .loading: "loading"
        case .notEnabled: "notEnabled"
        case .temporaryUnavailable: "temporaryUnavailable"
        case .availableToStake: "availableToStake"
        case .staked: "staked"
        }
    }
}

public extension StakingManagerState {
    struct Staked: Hashable {
        public let balances: [StakingBalanceInfo]
        public let yieldInfo: YieldInfo
        public let canStakeMore: Bool

        public func balance(validator: String) -> StakingBalanceInfo? {
            balances.first(where: { $0.validatorAddress == validator })
        }
    }
}
