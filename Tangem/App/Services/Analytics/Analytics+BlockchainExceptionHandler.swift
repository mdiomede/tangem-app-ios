//
//  BlockchainExceptionHandler.swift
//  Tangem
//
//  Created by skibinalexander on 06.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Firebase

extension Analytics {
    struct BlockchainExceptionHandler: ExternalExceptionHandler {
        func log(exception message: String, for host: String) {
            Analytics.log(
                event: .blockchainSdkException,
                params: [.host: host, .errorDescription: message],
                analyticsSystems: [.crashlytics]
            )
        }
    }
}
