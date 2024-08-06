//
//  StakeKitDTO+EstimateGas.swift
//  TangemStaking
//
//  Created by Dmitry Fedorov on 06.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension StakeKitDTO {
    enum EstimateGas {
        enum EnterAction {
            struct Request: Encodable {
                let integrationId: String
                let addresses: Address
                let args: Args

                struct Address: Encodable {
                    let address: String
                    let explorerUrl: String?

                    init(address: String, explorerUrl: String? = nil) {
                        self.address = address
                        self.explorerUrl = explorerUrl
                    }
                }
            }
        }

        typealias ExitAction = EnterAction

        enum PendingAction {
            struct Request: Encodable {
                let type: Actions.ActionType
                let integrationId: String
                let passthrough: String
                let addresses: Address
                let args: Args
            }
        }

        struct Args: Encodable {
            let amount: String
        }

        struct Response: Decodable {
            let amount: String?
            let token: Token
            let gasLimit: String
        }
    }
}
