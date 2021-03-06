//
//  paletteStore.swift
//  EmojiArt
//
//  Created by wilson agene on 3/24/22.
//

import SwiftUI

struct Palette: Identifiable, Codable, Hashable {
    var name: String
    var emojis: String
    var id: Int
    
    fileprivate init(name: String, emojis: String, id: Int) {
        self.name = name
        self.emojis = emojis
        self.id = id
    }
}

class PaletteStore: ObservableObject {
    let name: String
    
    @Published var palettes = [Palette]() {
        didSet {
            storeInUserDefaults()
        }
    }
    
    private func storeInUserDefaults() {
        UserDefaults.standard.set(try? JSONEncoder().encode(palettes), forKey: userDefaultsKey)
    }
    
    private var userDefaultsKey: String {
        "paletteStore:" + name
    }
    private func restoreFromUserDefaults() {
        if let jsonData = UserDefaults.standard.data(forKey: userDefaultsKey),
        let decodedpalettes = try? JSONDecoder().decode(Array<Palette>.self, from: jsonData) {
            palettes = decodedpalettes
        }
//        UserDefaults.standard.set(palettes, forKey: userDefaultsKey)
    }
    
    init (named name: String) {
        self.name = name
        if palettes.isEmpty {
            print("using built-in palette")
            insertPalette(named: "Vehicles", emojis: "ðððððŧðððððððððĩððððšððīðēðððððððððâïļð°âĩïļðððŦðŽâĩïļ" )
            insertPalette(named: "Sports", emojis: "â―ïļððâūïļðĨðąðĨððūðŠðâ·âđðūââïļðĪžââïļâđðūââïļðĪžðĪūðïļââïļðĪūââïļððââïļ" )
            insertPalette(named: "Music", emojis: "ðķðžðĩðĪð§ðļðĨðđðšðšðŧð·ðŠðŠðŠ" )
            insertPalette(named: "Animals", emojis: "ððĶðĶ­ðððĶĢðĶ§ðĶð ððģððĶðĶðŠðŦðððĶŽðĶðĶðððĶðððĶððĶŪðâðĶšðŠķððââŽðĶððĶĪðĶðĶðĶĒðĶĐðĶĒððĶðĶĻðĶŦðĶĶðūðĶĨðĶŦððĶĻðĶŦðððŋðð" )
            insertPalette(named: "Animal Faces", emojis:  "ðķðąð­ðđð°ðĻðŧââïļðžðŧðĶðŊðĶðŪð·ð―ððððĩðļðð§ðĶðĪððīðšðĶ")
            insertPalette(named: "Flora", emojis: "ððēðŋðŠĩðąðģâïļðððððððŠīðððŠĻðūðĨð·ððšðļðžðŧð" )
            insertPalette(named: "Weather", emojis: "ðĄâïļâïļðĪðĨâïļðĶðĶð§ðĻâðĐâĄïļâïļâïļâïļðĻðŠð§ðŽâïļð" )
            insertPalette(named: "COVID", emojis: "ðĪŪðĪ§ðĪððĶ " )
            insertPalette(named: "Face",  emojis: "ðððððĨēðĪĢððâšïļððððððĨ°ððððððððð§ðĪĻðĪŠðððĪððĨļðĪĐðĨģðððððððâđïļðĢðð­ðĒðĨšðŦðŦðĐðĪð ðĄðĪŽðĪŊðąðķâðŦïļðĨķðĨĩðģðĻð°ðĨððĪðĪ­ðĪðĪŦðĪĨðķððŽðððŊðĶð§ðŪðēðŪâðĻðŠðīðĨąðĪĪðĩðĩâðŦðĪðĨīðĪĒðĪðĪð·ðĪ§ðĪŪðĪðĪ " )
        } else {
            print("succesfully loaded palettes from UserDefults: \(palettes)")
        }
    }

// MARK - Intent
    
func  palette(at index: Int) -> Palette {
    let safeIndex = min(max(index, 0), palettes.count - 1)
    return palettes[safeIndex]
}

@discardableResult
func removePalette(at index: Int) -> Int {
    if palettes.count > 1, palettes.indices.contains(index) {
        palettes.remove(at: index)
    }
    return index % palettes.count
}

func insertPalette(named name: String, emojis: String? = nil, at index: Int = 0) {
    let unique = (palettes.max(by: { $0.id < $1.id})?.id ?? 0) + 1
    let palette = Palette(name: name, emojis: emojis ?? " ", id: unique)
    let safeindex = min(max(index, 0), palettes.count)
    palettes.insert(palette, at: safeindex)
    }
}
