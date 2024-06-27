//
//  CommonPushNotificationsInteractor.swift
//  Tangem
//
//  Created by m3g0byt3 on 26.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class CommonPushNotificationsInteractor {
    private var isFeatureFlagEnabled: Bool { FeatureProvider.isAvailable(.pushNotifications) }

    private var didPostponeRequest = false

    private let pushNotificationsService: PushNotificationsService

    init(pushNotificationsService: any PushNotificationsService) {
        self.pushNotificationsService = pushNotificationsService
    }

    @MainActor
    func isAvailable() async -> Bool {
        // Apparently, short-circuit operators like `&&` don't work with async-await, and since we want to preserve
        // short-circuit semantics here - the first condition is checked using plain guard
        guard isFeatureFlagEnabled else {
            return false
        }

        return await pushNotificationsService.isAvailable
    }

    func allowRequest(in flow: PermissionRequestFlow) {
        // TODO: Andrey Fedorov - Add actual implementation
    }

    func postponeRequest(in flow: PermissionRequestFlow) {
        // TODO: Andrey Fedorov - Add actual implementation
    }
}

// MARK: - Auxiliary types

extension CommonPushNotificationsInteractor {
    enum PermissionRequestFlow {
        enum NewUserState {
            /// User starts the app for the first time, accept TOS, etc.
            case userOnboarding
            /// User adds first wallet to the app, performs backup, etc.
            case walletOnboarding
            /// User completed all onboarding procedures and using app normally.
            case normalUsage
        }

        case newUser(state: NewUserState)
        case existingUser
    }
}
