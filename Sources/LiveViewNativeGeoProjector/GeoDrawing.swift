//
//  GeoDrawing.swift
//  LiveViewNativeGeoProjector
//
//  Created by Adrian Schönig on 17/9/2024.
//

import SwiftUI
import LiveViewNative
import GeoDrawer
import GeoJSONKit

#if canImport(UIKit)
typealias NSUIColor = UIColor
#elseif canImport(AppKit)
typealias NSUIColor = NSColor
#endif

@LiveElement
public struct GeoDrawing<Root: RootRegistry>: View {
  
  @LiveElementIgnored
  @StateObject private var coordinator = GeoDrawingCoordinator()
  
  @_documentation(visibility: public)
  private var url: String? = nil
  
  @_documentation(visibility: public)
  private var projection: String? = nil
  
  @LiveElementIgnored
  @Environment(\.colorScheme) var colorScheme
  
  public var body: some View {
    GeoMap(
      contents: coordinator.contents,
      projection: coordinator.projection,
      zoomTo: coordinator.boundingBox,
      mapBackground: coordinator.mapBackground,
      mapOutline: coordinator.mapOutline,
      mapBackdrop: coordinator.mapBackdrop
    )
    .onAppear { coordinator.didAppear() }
    .onChange(of: projection, initial: true) { _, new in
      coordinator.projectionMode = new.flatMap(GeoDrawer.ProjectionMode.init(rawValue:)) ?? .automatic
    }
    .onChange(of: url, initial: true) { _, new in coordinator.load(url) }
    .onChange(of: colorScheme, initial: true) { _, new in coordinator.colorScheme = new }
  }
  
  @MainActor
  final class GeoDrawingCoordinator: ObservableObject {
    init() {}
    
    @Published var projectionMode: GeoDrawer.ProjectionMode = .automatic
    
    @Published var continentContent: [GeoDrawer.Content] = []
    
    @Published var mapContent: [GeoDrawer.Content] = []
    
    @Published var boundingBox: GeoJSON.BoundingBox?
    
    @Published var colorScheme: ColorScheme?  {
      didSet { updateContinents() }
    }
    
    @Published var loadError: Error? = nil
    
    var mapBackground: NSUIColor { (colorScheme == .dark) ? #colorLiteral(red: 0.1019607843, green: 0.168627451, blue: 0.3803921569, alpha: 1) : #colorLiteral(red: 0.7411764706, green: 0.9098039216, blue: 0.9764705882, alpha: 1) }
    var mapOutline: NSUIColor    { (colorScheme == .dark) ? #colorLiteral(red: 0.1734354066, green: 0.2471963301, blue: 0.4649964373, alpha: 1) : #colorLiteral(red: 0.9294117647, green: 0.9254901961, blue: 0.9215686275, alpha: 1) }
    var mapBackdrop: NSUIColor   { (colorScheme == .dark) ? #colorLiteral(red: 0.1208299026, green: 0.1530924439, blue: 0.2066171169, alpha: 1) : #colorLiteral(red: 0.9689704984, green: 0.9648820153, blue: 0.9607935322, alpha: 1) }

    var countries: GeoJSON? {
      didSet { updateContinents() }
    }
    
    var contents: [GeoDrawer.Content] {
      continentContent + mapContent
    }
    
    var projection: GeoProjector.Projection {
      if let boundingBox {
        return projectionMode.resolve(for: boundingBox)
      } else {
        return Projections.EqualEarth()
      }
    }
    
    private func updateContinents() {
      guard let countries, let colorScheme else { return }
      let isDark = (colorScheme == .dark)
      let foreground: NSUIColor        = isDark ? #colorLiteral(red: 0.1647058824, green: 0.3215686275, blue: 0.3058823529, alpha: 1) : #colorLiteral(red: 0.8705882353, green: 0.9411764706, blue: 0.8039215686, alpha: 1)
      let foregroundStroke: NSUIColor  = isDark ? #colorLiteral(red: 0.229531881, green: 0.4481336723, blue: 0.426273493, alpha: 0.5) : #colorLiteral(red: 0.7407690425, green: 0.8008313973, blue: 0.6840434852, alpha: 0.50303959)
      
      continentContent = GeoDrawer.Content.content(
        for: countries,
        color: foreground.cgColor,
        polygonStroke: (foregroundStroke.cgColor, width: 0.5)
      )
    }
    
    func didAppear() {
#warning("TODO: Only do this once, not for each drawing.")
      self.countries = try? GeoDrawer.Content.countries()
    }
    
    func load(_ urlString: String?) {
      guard let url = urlString.flatMap(URL.init(string:)) else { return }
      
      Task {
        do {
          let (data, _) = try await URLSession.shared.data(from: url)
          let geoJSON = try GeoJSON(data: data)
          
          if let provided = geoJSON.boundingBox {
            self.boundingBox = provided
          } else {
            self.boundingBox = .suggestedBox(for: geoJSON.positions)
          }
          
          self.mapContent = GeoDrawer.Content.content(
            for: geoJSON,
            color: NSUIColor.red.cgColor
          )
          
          
        } catch {
          self.loadError = error
        }
      }
    }
  }
}
