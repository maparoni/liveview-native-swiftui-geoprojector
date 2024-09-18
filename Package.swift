// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "LiveViewNativeGeoProjector",
  platforms: [
    .iOS("17.0"),
    .macOS("13.0"),
  ],
  products: [
    .library(
      name: "LiveViewNativeGeoProjector",
      targets: ["LiveViewNativeGeoProjector"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/liveview-native/liveview-client-swiftui.git", from: "0.3.0"),
    .package(url: "https://github.com/maparoni/GeoProjector.git", from: "0.2.0"),
  ],
  targets: [
    .target(
      name: "LiveViewNativeGeoProjector",
      dependencies: [
        .product(name: "LiveViewNative", package: "liveview-client-swiftui"),
        .product(name: "GeoDrawer", package: "GeoProjector"),
      ]
    ),
    
  ]
)
