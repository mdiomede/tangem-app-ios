//
//  PolkaDotAccountHealthChecker.swift
//  Tangem
//
//  Created by Andrey Fedorov on 21.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

final class PolkaDotAccountHealthChecker {
    private let provider = TangemProvider<SubscanAPITarget>() // TODO: Andrey Fedorov - Move into separate entity like network provider
    private let decoder: JSONDecoder // TODO: Andrey Fedorov - Move into separate entity like network provider

    // TODO: Andrey Fedorov - Protect access to all storage properties
    @AppStorageCompat(StorageKeys.analyzedAccounts)
    private var analyzedAccounts: [String] = []

    @AppStorageCompat(StorageKeys.analyzedPages)
    private var analyzedNonceCountMismatches: [String] = []

    @AppStorageCompat(StorageKeys.analyzedPages)
    private var analyzedPages: [String: [Int]] = [:]

    private let isTestnet: Bool

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        setup() // TODO: Andrey Fedorov - Perform setup lazily instead
    }

    func analyzeAccountIfNeeded(_ account: String) {
        if analyzedAccounts.contains(account) {
            return
        }

        runTask(in: self) { try await $0.scheduleNormalHealthCheck(for: account) }
    }

    private func setup() {
        runTask(in: self) { await $0.setupObservers() }
    }

    private func setupObservers() async {
        for await _ in NotificationCenter.default.notifications(named: UIApplication.backgroundRefreshStatusDidChangeNotification) {
            handleBackgroundRefreshStatusChange()
        }
        for await _ in NotificationCenter.default.notifications(named: UIApplication.didEnterBackgroundNotification) {
            handleApplicationStatusChange(isBackground: true)
        }
        for await _ in NotificationCenter.default.notifications(named: UIApplication.willEnterForegroundNotification) {
            handleApplicationStatusChange(isBackground: false)
        }
    }

    private func scheduleNormalHealthCheck(for account: String) async throws {
        await checkNonceCountMismatch(for: account)
        await checkImmortalTransactions(for: account)
    }

    private func checkNonceCountMismatch(for account: String) async {
        // TODO: Andrey Fedorov - check if we've alreade have in-flight check of this kind
        if analyzedNonceCountMismatches.contains(account) {
            return
        }

        // TODO: Andrey Fedorov - Add retries (using common helper perhaps?)
        // TODO: Andrey Fedorov - Try to map API error first (using common helper perhaps?)
        do {
            let accountInfo = try await provider
                .asyncRequest(for: .init(isTestnet: isTestnet, target: .getAccountInfo(address: account)))
                .filterSuccessfulStatusAndRedirectCodes()
                .map(SubscanAPIResult.AccountInfo.self, using: decoder)
                .data
                .account

            if analyzedNonceCountMismatches.contains(account) {
                return
            }

            // `accountInfo.nonce` can be equal to or greater than the count of extrinsics,
            // but can't it be less (unless the account has been reset)
            let metric: AccountHealthMetric = .hasNonceCountMismatch(value: accountInfo.nonce < accountInfo.countExtrinsic)
            sendAccountHealthMetric(metric)
            analyzedNonceCountMismatches.append(account)
        } catch {
            // TODO: Andrey Fedorov - Catch error
        }
    }

    private func checkImmortalTransactions(for account: String) async {
        // TODO: Andrey Fedorov - check if we've alreade have in-flight check of this kind
    }

    private func scheduleBackgroundHealthCheck(for account: String) {}

    @MainActor
    private func handleBackgroundRefreshStatusChange() {
        // TODO: Andrey Fedorov - re-schedule bg job if user enabled bg refresh
    }

    @MainActor
    private func handleApplicationStatusChange(isBackground: Bool) {
        // TODO: Andrey Fedorov - re-schedule bg job if user enabled bg refresh
    }

    @MainActor
    private func sendAccountHealthMetric(_ metric: AccountHealthMetric) {}
}

// MARK: - Auxiliary types

private extension PolkaDotAccountHealthChecker {
    enum AccountHealthMetric {
        case hasNonceCountMismatch(value: Bool)
        case hasImmortalTransaction(value: Bool)
    }
}

// MARK: - Constants

private extension PolkaDotAccountHealthChecker {
    enum StorageKeys: String, RawRepresentable {
        case analyzedAccounts = "polka_dot_account_health_checker_analyzed_accounts"
        case analyzedNonceMismatches = "polka_dot_account_health_checker_analyzed_nonce_mismatches"
        case analyzedPages = "polka_dot_account_health_checker_analyzed_pages"
    }
}
