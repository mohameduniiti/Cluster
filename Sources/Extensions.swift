//
//  Extensions.swift
//  Cluster
//
//  Created by Lasha Efremidze on 4/15/17.
//  Copyright © 2017 efremidze. All rights reserved.
//

import Foundation
import MapKit

extension MKMapRect {
    init(minX: Double, minY: Double, maxX: Double, maxY: Double) {
        self.init(x: minX, y: minY, width: abs(maxX - minX), height: abs(maxY - minY))
    }
    init(x: Double, y: Double, width: Double, height: Double) {
        self.init(origin: MKMapPoint(x: x, y: y), size: MKMapSize(width: width, height: height))
    }
    var minX: Double { return MKMapRectGetMinX(self) }
    var minY: Double { return MKMapRectGetMinY(self) }
    var midX: Double { return MKMapRectGetMidX(self) }
    var midY: Double { return MKMapRectGetMidY(self) }
    var maxX: Double { return MKMapRectGetMaxX(self) }
    var maxY: Double { return MKMapRectGetMaxY(self) }
    func intersects(_ rect: MKMapRect) -> Bool {
        return MKMapRectIntersectsRect(self, rect)
    }
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        return MKMapRectContainsPoint(self, MKMapPointForCoordinate(coordinate))
    }
}

let CLLocationCoordinate2DMax = CLLocationCoordinate2D(latitude: 90, longitude: 180)
let MKMapPointMax = MKMapPointForCoordinate(CLLocationCoordinate2DMax)

extension CLLocationCoordinate2D: Hashable {
    public var hashValue: Int {
        return latitude.hashValue ^ longitude.hashValue
    }
}

public func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
    return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
}

typealias ZoomScale = Double
extension ZoomScale {
    func zoomLevel() -> Double {
        let totalTilesAtMaxZoom = MKMapSizeWorld.width / 256
        let zoomLevelAtMaxZoom = log2(totalTilesAtMaxZoom)
        return max(0, zoomLevelAtMaxZoom + floor(log2(self) + 0.5))
    }
    func cellSize() -> Double {
        switch self {
        case 13...15:
            return 64
        case 16...18:
            return 32
        case 19 ..< .greatestFiniteMagnitude:
            return 16
        default: // Less than 13
            return 88
        }
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

private let radiusOfEarth: Double = 6372797.6

extension CLLocationCoordinate2D {
    func coordinate(onBearingInRadians bearing: Double, atDistanceInMeters distance: Double) -> CLLocationCoordinate2D {
        let distRadians = distance / radiusOfEarth // earth radius in meters
        
        let lat1 = latitude * .pi / 180
        let lon1 = longitude * .pi / 180
        
        let lat2 = asin(sin(lat1) * cos(distRadians) + cos(lat1) * sin(distRadians) * cos(bearing))
        let lon2 = lon1 + atan2(sin(bearing) * sin(distRadians) * cos(lat1), cos(distRadians) - sin(lat1) * sin(lat2))
        
        return CLLocationCoordinate2D(latitude: lat2 * 180 / .pi, longitude: lon2 * 180 / .pi)
    }
}

extension Array where Element: MKAnnotation {
    func subtracted(_ other: [Element]) -> [Element] {
        return filter { item in !other.contains { $0.coordinate == item.coordinate } }
    }
    mutating func subtract(_ other: [Element]) {
        self = self.subtracted(other)
    }
    mutating func add(_ other: [Element]) {
        self.append(contentsOf: other)
    }
}
