//
//  ExpressTransactionValue.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 06.08.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressTransactionValue {
    /// `amount` - Value to simple `send` operation
    case transfer(amount: Decimal)

    /// `txValue` -  Have to be sent as coin value
    /// `data` - Contains necessary data for contract which will provide swap
    case contractCall(txValue: Decimal, data: Data)
}
