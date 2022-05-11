//
//  EmojiArtApp.swift
//  Shared
//
//  Created by wilson agene on 4/4/22.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    @StateObject var paletteStore = PaletteStore(named: "Default")
    
    var body: some Scene {
        DocumentGroup(newDocument: { EmojiArtDocument() }) { config in
            EmojiArtDocumentVeiw(document: config.document)
                .environmentObject(paletteStore)
        }
    }
}
