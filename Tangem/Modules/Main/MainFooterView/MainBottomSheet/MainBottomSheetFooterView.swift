//
//  MainBottomSheetFooterView.swift
//  Tangem
//
//  Created by Andrey Fedorov on 28.09.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct MainBottomSheetFooterView: View {
    var body: some View {
        VStack(spacing: 0.0) {
            FixedSpacer.vertical(14.0)

            // `MainBottomSheetHeaderInputView` is used here as a dummy noninteractive placeholder
            MainBottomSheetHeaderInputView(
                searchText: .constant(""),
                isTextFieldFocused: .constant(false),
                textFieldAllowsHitTesting: false
            )
            .bottomScrollableSheetCornerRadius()
            .bottomScrollableSheetGrabber()
            .bottomScrollableSheetShadow()
        }
    }
}
