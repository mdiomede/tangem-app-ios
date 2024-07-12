//
//  CommonStakingManager.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 28.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class CommonStakingManager {
    private let wallet: StakingWallet
    private let yield: YieldInfo
    private let provider: StakingAPIProvider
    private let logger: Logger

    init(
        wallet: StakingWallet,
        yield: YieldInfo,
        provider: StakingAPIProvider,
        logger: Logger
    ) {
        self.wallet = wallet
        self.yield = yield
        self.provider = provider
        self.logger = logger
    }
}

extension CommonStakingManager: StakingManager {
    func getFee(amount: Decimal, validator: String) async throws {
        let action = try await provider.enterAction(
            amount: amount,
            address: wallet.defaultAddress,
            validator: validator,
            integrationId: yield.id
        )
    }

    func getTransaction() async throws {
        // TBD: https://tangem.atlassian.net/browse/IOS-6897
    }
}

public enum StakingManagerError: Error {
    case notFound
}
