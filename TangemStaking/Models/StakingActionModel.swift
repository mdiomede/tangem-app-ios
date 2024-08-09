//
//  EnterAction.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 12.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum StakingActions {
    public enum Enter {}
    public enum Exit {}
    public enum Pending {}
}

public struct StakingActionModel<T>: Hashable {
    public let id: String
    public let status: ActionStatus
    public let currentStepIndex: Int
    public let transactions: [ActionTransaction]
}

public typealias EnterActionModel = StakingActionModel<StakingActions.Enter>
public typealias ExitActionModel = StakingActionModel<StakingActions.Exit>
public typealias PendingActionModel = StakingActionModel<StakingActions.Pending>
