//
//  GeoProjectorRegistry.swift
//  LiveViewNativeGeoProjector
//
//  Created by Adrian Schönig on 17/9/2024.
//

import LiveViewNative
import LiveViewNativeStylesheet
import SwiftUI

public extension Addons {
  
  @Addon
  struct GeoProjector<Root: RootRegistry> {
    public enum TagName: String {
      /// `<GeoDrawing>`
      case geoDrawing = "GeoDrawing"
    }
      
    public static func lookup(_ name: TagName, element: ElementNode) -> some View {
      switch name {
      case .geoDrawing:
        GeoDrawing<Root>()
      }
    }
  }
  
}
