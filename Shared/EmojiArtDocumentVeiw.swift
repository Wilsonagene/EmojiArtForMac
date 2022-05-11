//
//  EmojiArtDocumentVeiw.swift
//  EmojiArt
//
//  Created by wilson agene on 3/19/22.
//

import SwiftUI

struct EmojiArtDocumentVeiw: View {
    @ObservedObject var document: EmojiArtDocument
    
    @Environment(\.undoManager) var undoManager
    
    @ScaledMetric var  defaultEmojiFontSize: CGFloat = 40
    var body: some View {
        VStack (spacing: 0) {
            documentBody
            PaletteChoser(emojiFontSize: defaultEmojiFontSize)
        }
    }
    
    var documentBody: some View {
        GeometryReader { geometry in
                ZStack {
                    Color.white
                        OptionalImage(uiImage: document.backgroundImage)
                        .scaleEffect(zoomScale)
                        .position(convertFromEmojiCoordinates((0,0), in: geometry))
                      .gesture(doubleTapToZoom(in: geometry.size))
                    if document.backgroundImageFetchStatus == .fetching {
                        ProgressView().scaleEffect(2)
                    } else {
                        ForEach(document.emojis) { emoji in
                            Text(emoji.text)
                                .font(.system(size: fontSize(for: emoji)))
                                .scaleEffect(zoomScale)
                                .position(position(for: emoji, in: geometry))
                        }
                    }
                }
                .clipped()  
                .onDrop(of:  [.utf8PlainText, .url, .image], isTargeted: nil) { providers, location in
                     drop(providers: providers, at: location, in: geometry)
                }
                .gesture(panGesture().simultaneously(with: zoomGesture()))
                .alert(item: $alertToShow) { alertToShow in
                    //return Alert
                    alertToShow.alert()
                }
                .onChange(of: document.backgroundImageFetchStatus) { status in
                    switch status {
                    case .failed(let url):
                        showBackgroundImageFetchFailedAlert(url)
                    default:
                        break
                    }
                }
                .onReceive(document.$backgroundImage) {image in
                    if autozoom {
                        zoomToFit(image, in: geometry.size)
                    }
                }
                .compactableToolbar {
                        AnimatedActionButton(title: "Paste Backgorund", systemImage: "doc.on.clipboard") {
                            pasteBackgorund()
                        }
                    if Camera.isAvailable {
                            AnimatedActionButton(title: "Take Photo", systemImage: "camera") {
                                backgroundPicker = .camera
                            }
                        }
                    if PhotoLibrary.isAvailable {
                            AnimatedActionButton(title: "Search Photos", systemImage: "photo") {
                                backgroundPicker = .libary
                            }
                        }
                            #if os(iOS)
                        if let undoManager = undoManager {
                            if undoManager.canUndo {
                                AnimatedActionButton(title: undoManager.undoActionName, systemImage: "arrow.uturn.backward") {
                                    undoManager.undo()
                                }
                            }
                            if undoManager.canRedo {
                                AnimatedActionButton(title: undoManager.redoActionName, systemImage: "arrow.uturn.forward") {
                                    undoManager.redo()
                                }
                            }
                        }
                    #endif
                    }
                .sheet(item: $backgroundPicker) { pickerType in
                    switch pickerType {
                    case .camera: Camera(handlePickedImage: { image in handlePickedBackgroundImage( image) })
                    case .libary: PhotoLibrary(handlePickedImage: { image in handlePickedBackgroundImage( image) } )
                    }
                }
            }
        }
    private func handlePickedBackgroundImage(_ image: UIImage?) {
        autozoom = true
        if let imageData = image?.imageData {
            document.setBackground(.imagedata(imageData), undoManager: undoManager)
        }
        backgroundPicker = nil
    }
    
    
    
    @State private var backgroundPicker: BackgroundPickerType?
    
    enum BackgroundPickerType: String, Identifiable {
        case camera
        case libary
        var id: String {rawValue}
    }
    
    private func pasteBackgorund() {
        autozoom = true
        if let imageData = Pasteboard.imageData {
            document.setBackground(.imagedata(imageData), undoManager: undoManager)
        } else if let url = Pasteboard.imageURL {
            document.setBackground(.url(url), undoManager: undoManager)
        } else {
            alertToShow = IdentifiableAlert(
                title: "Paste Background",
                message: "There is no image currently on pasteboard"
            )
        }
    }
    
    @State private var autozoom = false 
    
    @State private var alertToShow: IdentifiableAlert?
    
    private func showBackgroundImageFetchFailedAlert(_ url: URL) {
        alertToShow = IdentifiableAlert(id: "fetch failed" + url.absoluteString, alert: {
            Alert(
                title: Text("Background Image Fetch"),
                message: Text("Couldn't load image from \(url)."),
                dismissButton: .default(Text("OK"))
            )
        })
    }
    
    // MARK: DRAG AND DROP
    private func drop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        var found = providers.loadObjects(ofType: URL.self) { url in
            autozoom = true 
            document.setBackground(.url(url.imageURL), undoManager: undoManager)
        }
        #if os(iOS)
        if !found {
            found = providers.loadObjects(ofType: UIImage.self) { image in
                if let data = image.jpegData(compressionQuality: 1.0) {
                    document .setBackground(.imagedata(data), undoManager: undoManager)
                }
            }
        }
        #endif
        if !found { 
            found =  providers.loadObjects(ofType: String.self) { string in
                if let emoji = string.first, emoji.isEmoji {
                    document.addEmoji(
                    String(emoji),
                     at: convertToEmojiCoodinate(location, in: geometry),
                     size: defaultEmojiFontSize / zoomScale,
                        undoManager: undoManager
                    )
                }
            }
        }
       
        return found
    }
        
      // MARK: - Positioning/Sizing Emoji
    private func position (for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy ) -> CGPoint {
        convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry)
    }
    
    private func convertToEmojiCoodinate(_ location: CGPoint, in geometry: GeometryProxy ) -> (x: Int, y: Int) {
        let center =  geometry .frame(in: .local).center
        let location = CGPoint (
            x: (location.x - panOffset.width - center.x) / zoomScale,
            y: (location.y  - panOffset.height - center.y) / zoomScale
        )
        return (Int(location.x), Int(location.y)) 
    }
    
    private func convertFromEmojiCoordinates (_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
        let center =  geometry .frame(in: .local).center
        return CGPoint (
            x: center.x + CGFloat(location.x) * zoomScale + panOffset.width,
            y: center.y + CGFloat(location.y) * zoomScale + panOffset.height
        )
    }
    
    private func fontSize (for emoji: EmojiArtModel.Emoji) -> CGFloat {
        CGFloat(emoji.size)
    }
    
    // MARK: - Panning
    
    @SceneStorage("EmojiArtDocumentView.steadyStatePanOffset")
    private var steadyStatePanOffset: CGSize = CGSize.zero
    @GestureState private var gesturePanOffset: CGSize = CGSize.zero
    
    private var panOffset: CGSize  {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureVaule, gesturePanOffset, _ in
                gesturePanOffset = latestDragGestureVaule.translation / zoomScale
            }
            .onEnded { finalDragGestureValue in
                steadyStatePanOffset =  steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
            }
    }
    // MARK: zooming
    
    @SceneStorage("EmojiArtDocumentView.SteadyStateZoom")
    private var steadyStatezoomScale: CGFloat = 1
    @GestureState private var gestureZoomScale: CGFloat = 1

    private var zoomScale: CGFloat {
        steadyStatezoomScale * gestureZoomScale
    }
    
    private func zoomGesture () -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, _ in
                gestureZoomScale = latestGestureScale
            }
            .onEnded{ gestureScaleAtEnd in
                steadyStatezoomScale *= gestureScaleAtEnd
            }
    }
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count:  2)
            .onEnded {
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size)
                }
        }
                }
               
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image,  image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            steadyStatePanOffset = .zero
            steadyStatezoomScale = min(hZoom, vZoom)
        }
    }


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentVeiw(document: EmojiArtDocument())
        }
    }
}
