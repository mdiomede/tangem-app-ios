//
//  StakeKitDTO+Actions.swift
//  TangemStaking
//
//  Created by Sergey Balashov on 27.05.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

extension StakeKitDTO {
    enum Actions {
        enum ActionType: String, Hashable, Codable {
            case stake = "STAKE"
            case unstake = "UNSTAKE"
            case claimRewards = "CLAIM_REWARDS"
            case restakeRewards = "RESTAKE_REWARDS"
            case withdraw = "WITHDRAW"
            case restake = "RESTAKE"
            case claimUnstaked = "CLAIM_UNSTAKED"
            case unlockLocked = "UNLOCK_LOCKED"
            case stakeLocked = "STAKE_LOCKED"
            case vote = "VOTE"
            case revoke = "REVOKE"
            case voteLocked = "VOTE_LOCKED"
            case revote = "REVOTE"
            case rebond = "REBOND"
            case migrate = "MIGRATE"
            case unknown = "UNKNOWN"
        }

        enum ActionStatus: String, Hashable, Codable {
            case canceled = "CANCELED"
            case created = "CREATED"
            case waitingForNext = "WAITING_FOR_NEXT"
            case processing = "PROCESSING"
            case failed = "FAILED"
            case success = "SUCCESS"
            case unknown = "UNKNOWN"
        }

        struct ActionArgs: Decodable {
            let amount: Amount?
            let duration: Duration?
            let validatorAddress: Required?
            let validatorAddresses: Required?
            let nfts: [NFT]?
            let tronResource: TronResource?
            let signatureVerification: Required?

            struct Amount: Decodable {
                let required: Bool
                let minimum: Decimal
                let maximum: Decimal?
            }

            struct Duration: Codable {
                let required: Bool
                let minimum: Int?
                let maximum: Int?
            }

            struct NFT: Decodable {
                let baycId: Required?
                let maycId: Required?
                let bakcId: Required?
            }

            struct TronResource: Codable {
                let required: Bool
                let options: [String]
            }
        }

        enum Get {
            struct Request: Encodable {
                let actionId: String
            }

            struct Response: Decodable {}
        }

        enum Enter {
            struct Request: Encodable {
                let integrationId: String
                let addresses: Address
                let args: Args

                struct Args: Encodable {
                    let amount: String
                    let validatorAddress: String?
                    let validatorAddresses: [Address]
                }
            }

            struct Response: Decodable {
                let id: String
                let integrationId: String
                let status: ActionStatus
                let type: ActionType
                let currentStepIndex: Int
                let amount: String
                let validatorAddress: String?
                let validatorAddresses: [Address]?
                let transactions: [Transaction.Response]?
            }
        }

        enum Exit {
            struct Request: Encodable {
                let integrationId: String
                let addresses: Address
                let args: Args

                struct Args: Encodable {
                    let amount: String
                    let validatorAddress: String?
                }
            }

            struct Response: Decodable {
                let id: String
                let integrationId: String
                let status: ActionStatus
                let type: ActionType
                let currentStepIndex: Int
                let amount: String
                let validatorAddress: String?
                let validatorAddresses: [String]?
                let transactions: [Transaction.Response]?
            }
        }

        enum Pending {
            struct Request: Encodable {
                let type: ActionType
                let passthrough: String
                let args: Args

                struct Args: Encodable {
                    let amount: Decimal
                    let validatorAddress: String
                    let validatorAddresses: [String]?
                    let duration: Int?
                    let nfts: Ntfs?

                    init(
                        amount: Decimal,
                        validatorAddress: String,
                        validatorAddresses: [String]? = nil,
                        duration: Int? = nil,
                        nfts: StakeKitDTO.Actions.Pending.Request.Args.Ntfs? = nil
                    ) {
                        self.amount = amount
                        self.validatorAddress = validatorAddress
                        self.validatorAddresses = validatorAddresses
                        self.duration = duration
                        self.nfts = nfts
                    }

                    struct Ntfs: Encodable {
                        let baycId: String
                        let maycId: String
                        let bakcId: String
                    }
                }
            }

            struct Response: Decodable {
                let id: String
                let integrationId: String
                let status: ActionStatus
                let type: PendingAction
                let currentStepIndex: Int
                let amount: Decimal
                let USDAmount: Decimal
                let tokenId: String
                let validatorAddress: String
                let validatorAddresses: [String]
                let transactions: [Transaction.Response]?
            }
        }
    }

    struct PendingAction: Decodable {
        let type: PendingActionType
        let passthrough: String

        enum PendingActionType: String, Decodable {
            case STAKE
            case UNSTAKE
            case CLAIM_REWARDS
            case RESTAKE_REWARDS
            case WITHDRAW
            case RESTAKE
            case CLAIM_UNSTAKED
            case UNLOCK_LOCKED
            case STAKE_LOCKED
            case VOTE
            case REVOKE
            case VOTE_LOCKED
            case REVOTE
            case REBOND
            case MIGRATE
        }
    }
}
