import SwiftUI

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif

extension Image {
    init(platformImage: PlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: platformImage)
        #elseif canImport(AppKit)
        self.init(nsImage: platformImage)
        #endif
    }
}

extension PlatformImage {
    func pngDataRepresentation() -> Data? {
        #if canImport(UIKit)
        return pngData()
        #elseif canImport(AppKit)
        guard
            let tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffRepresentation)
        else {
            return nil
        }

        return bitmap.representation(using: .png, properties: [:])
        #endif
    }
}

extension View {
    @ViewBuilder
    func popLexNavigationChromeHidden() -> some View {
        #if os(macOS)
        self
        #else
        self.toolbar(.hidden, for: .navigationBar)
        #endif
    }

    @ViewBuilder
    func popLexKeyFieldStyle() -> some View {
        #if os(macOS)
        self
            .autocorrectionDisabled()
        #else
        self
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        #endif
    }

    @ViewBuilder
    func popLexSheetTitleStyle() -> some View {
        #if os(macOS)
        self
        #else
        self.navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
