//
//  SymbolItemWrapper.swift
//  Symbol Notifier
//
//  Created by Shai Kalev on 6/22/25.
//

import Foundation

final class SymbolItemWrapper: ObservableObject, Identifiable {
    let id: UUID
    @Published var symbolItem: SymbolItem

    init(_ item: SymbolItem) {
        self.symbolItem = item
        self.id = item.id
    }
}
