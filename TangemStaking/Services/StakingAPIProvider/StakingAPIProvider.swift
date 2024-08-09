//
//  StakingAPIProvider.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 27.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol StakingAPIProvider {
    func enabledYields() async throws -> [YieldInfo]
    func yield(integrationId: String) async throws -> YieldInfo
    func balances(wallet: StakingWallet) async throws -> [StakingBalanceInfo]?

    func estimateStakeFee(amount: Decimal, address: String, validator: String, integrationId: String) async throws -> Decimal
    func estimateUnstakeFee(amount: Decimal, address: String, validator: String, integrationId: String) async throws -> Decimal
    func estimatePendingFee(
        data: StakingAction.Pending,
        amount: Decimal,
        address: String,
        validator: String,
        integrationId: String
    ) async throws -> Decimal

    func enterAction(
        amount: Decimal,
        address: String,
        validator: String,
        integrationId: String
    ) async throws -> EnterActionModel
    func exitAction(
        amount: Decimal,
        address: String,
        validator: String,
        integrationId: String
    ) async throws -> ExitActionModel
    func pendingAction(
        data: StakingAction.Pending,
        amount: Decimal,
        validator: String,
        integrationId: String
    ) async throws -> PendingActionModel

    func transaction(id: String) async throws -> StakingTransactionInfo
    func patchTransaction(id: String) async throws -> StakingTransactionInfo
    func submitTransaction(hash: String, signedTransaction: String) async throws
    func submitHash(hash: String, transactionId: String) async throws
}
