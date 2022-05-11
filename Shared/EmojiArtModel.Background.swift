//
//  EmojiArtModel.Background.swift
//  EmojiArt
//
//  Created by wilson agene on 3/19/22.
//

import Foundation

extension EmojiArtModel {
    enum Background: Equatable, Codable {
         case blank
         case url(URL)
         case imagedata(Data)
        
        var url: URL? {
        switch self {
        case .url(let url): return url
        default: return nil
            }
        }
        
        var imageData: Data? {
            switch self {
            case .imagedata(let data): return data
            default: return nil
            }
        }
    }
}
