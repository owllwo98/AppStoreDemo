//
//  PointBorderText.swift
//  AppStoreDemo
//
//  Created by 변정훈 on 4/27/25.
//

import SwiftUI

private struct PointBorderText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(.blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue, lineWidth: 1)
            )
            .padding(2)
    }
}

extension View {
    func asPointBorderText() -> some View {
        modifier(PointBorderText())
    }
}
