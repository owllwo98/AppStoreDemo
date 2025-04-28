//
//  ButtonWrapper.swift
//  AppStoreDemo
//
//  Created by 변정훈 on 4/27/25.
//

import SwiftUI

private struct ButtonWrapper: ViewModifier {
    
    let action: () -> Void
    
    func body(content: Content) -> some View {
        Button(action: action) {
            content
        }
    }
}

extension View {
    func wrapToButton(_ action: @escaping () -> Void) -> some View {
        modifier(ButtonWrapper(action: action))
    }
}
