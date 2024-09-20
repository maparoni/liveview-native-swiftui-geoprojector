//
//  GeoDrawingCache.swift
//  LiveViewNativeGeoProjector
//
//  Created by Adrian Schönig on 20/9/2024.
//

import Foundation

import GeoDrawer
import GeoJSONKit

public protocol GeoDrawingContentProvider {
  
  func cachedContent(url: URL) async throws -> GeoJSON?
  
  func fetchContent(url: URL) async throws -> GeoJSON?
  
  func continents() async throws -> GeoJSON
}

extension GeoDrawingContentProvider {
  public func cachedContent(url: URL) async throws -> GeoJSON? {
    nil
  }
}

public class GeoDrawingContentManager {
  public static let shared = GeoDrawingContentManager()
  
  private init() {
    self.provider = DefaultProvider()
  }
  
  public var provider: GeoDrawingContentProvider
  
}

fileprivate actor DefaultProvider: GeoDrawingContentProvider {
  init() {}
  
  private var cachedContinents: GeoJSON?
  private var cache: [URL: (Date, GeoJSON)] = [:]
  
  func cachedContent(url: URL) async throws -> GeoJSON? {
    cache[url]?.1
  }
  
  func fetchContent(url: URL) async throws -> GeoJSON? {
    var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy)
    if let cacheDate = cache[url]?.0 {
      request.addValue(cacheDate.formatted(.iso8601), forHTTPHeaderField: "if-modified-since")
    }
    
    let (data, response) = try await URLSession.shared.data(for: request)
    if (response as? HTTPURLResponse)?.statusCode == 304 {
      return nil
    }
    let fresh = try GeoJSON(data: data)
    cache[url] = (Date(), fresh)
    return fresh
  }
  
  func continents() throws -> GeoJSON {
    if let cachedContinents {
      return cachedContinents
    } else {
      let fresh = try GeoDrawer.Content.countries()
      cachedContinents = fresh
      return fresh
    }
  }
}
