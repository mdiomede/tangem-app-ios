//
//  PushNotificationsService.swift
//  Tangem
//
//  Created by m3g0byt3 on 26.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol PushNotificationsService {
    @discardableResult
    func requestAuthorizationAndRegister() async -> Bool
}
