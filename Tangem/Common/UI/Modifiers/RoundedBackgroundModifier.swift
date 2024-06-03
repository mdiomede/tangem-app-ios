//
//  RoundedBackgroundModifier.swift
//  Tangem
//
//  Created by Andrew Son on 08/11/22.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct RoundedBackgroundModifier: ViewModifier {
    let verticalPadding: CGFloat
    let horizontalPadding: CGFloat
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let geometryEffect: GeometryEffect?

    func body(content: Content) -> some View {
        content
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, horizontalPadding)
            .background(
                backgroundColor
                    .modifier(ifLet: geometryEffect) {
                        $0.matchedGeometryEffect(id: $1.id, in: $1.namespace, isSource: $1.isSource)
                    }
            )
            .cornerRadiusContinuous(cornerRadius)
    }
}

extension View {
    private static var defaultCornerRadius: CGFloat { 14 }

    func roundedBackground(
        with color: Color,
        padding: CGFloat,
        radius: CGFloat = Self.defaultCornerRadius,
        geometryEffect: GeometryEffect? = .none
    ) -> some View {
        modifier(
            RoundedBackgroundModifier(
                verticalPadding: padding,
                horizontalPadding: padding,
                backgroundColor: color,
                cornerRadius: radius,
                geometryEffect: geometryEffect
            )
        )
    }

    func roundedBackground(
        with color: Color,
        verticalPadding: CGFloat,
        horizontalPadding: CGFloat,
        radius: CGFloat = Self.defaultCornerRadius,
        geometryEffect: GeometryEffect? = .none
    ) -> some View {
        modifier(
            RoundedBackgroundModifier(
                verticalPadding: verticalPadding,
                horizontalPadding: horizontalPadding,
                backgroundColor: color,
                cornerRadius: radius,
                geometryEffect: geometryEffect
            )
        )
    }

    func defaultRoundedBackground(
        with color: Color = Colors.Background.primary,
        geometryEffect: GeometryEffect? = .none
    ) -> some View {
        modifier(
            RoundedBackgroundModifier(
                verticalPadding: 12,
                horizontalPadding: 14,
                backgroundColor: color,
                cornerRadius: Self.defaultCornerRadius,
                geometryEffect: geometryEffect
            )
        )
    }
}
