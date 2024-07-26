//
//  SendFeeSummaryView.swift
//  Tangem
//
//  Created by Andrey Chukavin on 15.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendFeeSummaryView: View {
    @ObservedObject var data: SendFeeSummaryViewModel

    private var titleGeometryEffect: GeometryEffect?
    private var optionGeometryEffect: GeometryEffect?
    private var amountGeometryEffect: GeometryEffect?

    init(data: SendFeeSummaryViewModel) {
        self.data = data
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(data.title)
                .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                .lineLimit(1)
                .matchedGeometryEffect(titleGeometryEffect)
                .visible(data.titleVisible)

            FeeRowView(viewModel: data.feeRowViewModel)
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear(perform: data.onAppear)
    }
}

extension SendFeeSummaryView: Setupable {
    func titleGeometryEffect(_ effect: GeometryEffect?) -> Self {
        map { $0.titleGeometryEffect = effect }
    }

    func optionGeometryEffect(_ effect: GeometryEffect?) -> Self {
        map { $0.optionGeometryEffect = effect }
    }

    func amountGeometryEffect(_ effect: GeometryEffect?) -> Self {
        map { $0.amountGeometryEffect = effect }
    }
}

#Preview {
    GroupedScrollView(spacing: 14) {
        GroupedSection(
            SendFeeSummaryViewModel(
                title: "Network fee",
                feeRowViewModel: .init(
                    option: .market,
                    components: .loaded(.init(cryptoFee: "0.159817 MATIC", fiatFee: "0,22 $")),
                    style: .plain
                )
            )
        ) { data in
            SendFeeSummaryView(data: data)
        }

        GroupedSection(
            SendFeeSummaryViewModel(
                title: "Network Fee Network Fee Network Fee Network Fee Network Fee Network Fee Network Fee Network Fee",
                feeRowViewModel: .init(
                    option: .slow,
                    components: .loaded(.init(cryptoFee: "159 817 159 817.159817 MATIC", fiatFee: "100 120,22 $")),
                    style: .plain
                )
            )
        ) { data in
            SendFeeSummaryView(data: data)
        }
    }
    .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
}
