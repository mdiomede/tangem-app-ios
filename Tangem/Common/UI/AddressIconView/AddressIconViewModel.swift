//
//  AddressIconViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 02.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockiesSwift

class AddressIconViewModel {
    let size: CGFloat

    lazy var image: UIImage = {
        let blockies = Blockies(
            seed: address.lowercased(),
            size: numberOfBlocks,
            scale: scale,
            color: nil,
            bgColor: nil,
            spotColor: nil
        )

        return blockies.createImage() ?? UIImage()
    }()

    private let address: String
    private let numberOfBlocks = 12
    private let scale = 3

    init(address: String) {
        size = CGFloat(numberOfBlocks * scale)
        self.address = address
    }
}
