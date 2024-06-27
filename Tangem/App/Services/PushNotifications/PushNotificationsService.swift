//
//  PushNotificationsService.swift
//  Tangem
//
//  Created by m3g0byt3 on 26.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol PushNotificationsService {
    // TODO: Andrey Fedorov - Check the actual actor here, see https://forums.swift.org/t/mainactor-with-protocols/68801 and
    // https://forums.swift.org/t/use-a-protocol-of-mainactor-instead-of-concrete-mainactor-class-produces-an-error/72542
    /*@MainActor*/
    var isAvailable: Bool { get async }
}
