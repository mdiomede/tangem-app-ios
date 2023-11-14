//
//  WalletModel+ExpressWallet.swift
//  Tangem
//
//  Created by Sergey Balashov on 10.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping
import BlockchainSdk

extension TokenItem {
    var expressCurrency: TangemSwapping.ExpressCurrency {
        .init(
            contractAddress: contractAddress ?? ExpressConstants.coinContractAddress,
            network: blockchain.networkId
        )
    }
}

extension WalletModel: ExpressWallet {
    var currency: TangemSwapping.ExpressCurrency {
        tokenItem.expressCurrency
    }

    var address: String { defaultAddress }
}
