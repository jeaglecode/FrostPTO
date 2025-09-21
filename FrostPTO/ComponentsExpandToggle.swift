//  ExpandToggle.swift
//  FrostPTO
//
//  Created by Assistant on 9/21/25.
//

import SwiftUI

struct ExpandToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Button(action: toggle) {
            Image(systemName: isOn ? "chevron.down" : "chevron.up")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isOn ? .primary : .secondary)
                .frame(width: 24, height: 24)
                .padding(10) // invisible padding to enlarge hit area
                .contentShape(Rectangle())
                .frame(minWidth: 36, minHeight: 36, alignment: .center)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(isOn ? "Collapse" : "Expand"))
        .accessibilityAddTraits(.isButton)
    }

    private func toggle() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isOn.toggle()
        }
    }
}

#Preview {
    StatefulPreviewWrapper(false) { binding in
        ExpandToggle(isOn: binding)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}

// Helper for binding in previews
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    private let content: (Binding<Value>) -> Content

    init(_ value: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: value)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}
