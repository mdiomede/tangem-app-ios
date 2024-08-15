//
//  ExpressApprovePolicy.swift
//  TangemExpress
//
//  Created by Sergey Balashov on 04.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressApprovePolicy: Hashable, CaseIterable {
    case unlimited
    case specified

    public func amount(_ amount: Decimal) -> Decimal {
        switch self {
        case .specified:
            return amount
        case .unlimited:
            return .greatestFiniteMagnitude
        }
    }
}
