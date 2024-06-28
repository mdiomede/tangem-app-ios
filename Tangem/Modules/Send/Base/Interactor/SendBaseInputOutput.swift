//
//  SendBaseInputOutput.swift
//  Tangem
//
//  Created by Sergey Balashov on 28.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SendBaseInput: AnyObject {
    var isLoading: AnyPublisher<Bool, Never> { get }
}

protocol SendBaseOutput: AnyObject {
    func sendTransaction() -> AnyPublisher<SendTransactionSentResult, Never>
}
