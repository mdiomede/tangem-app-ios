//
//  SendFeeSummaryViewModel.swift
//  Tangem
//
//  Created by Andrey Chukavin on 15.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

class SendFeeSummaryViewModel: ObservableObject, Identifiable {
    let title: String
    @Published var titleVisible = true
    @Published var feeRowViewModel: FeeRowViewModel

    private var animateTitleOnAppear: Bool = false

    init(title: String, feeRowViewModel: FeeRowViewModel) {
        self.title = title
        self.feeRowViewModel = feeRowViewModel
    }

    func setAnimateTitleOnAppear(_ animateTitleOnAppear: Bool) {
        self.animateTitleOnAppear = animateTitleOnAppear
    }

    func onAppear() {
        if animateTitleOnAppear {
            titleVisible = false
            withAnimation(SendView.Constants.defaultAnimation) {
                titleVisible = true
            }
        }
    }
}
