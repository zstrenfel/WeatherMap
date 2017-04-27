//
//  WeatherLocation.swift
//  WeatherMap
//
//  Created by Zach Strenfel on 4/26/17.
//  Copyright © 2017 Zach Strenfel. All rights reserved.
//

import Foundation
import MapKit

class WeatherLocation: NSObject, MKAnnotation {
    
    //MARK: - Properties
    let locationName: String
    let weather: String
    let temp: Float
    let coordinate: CLLocationCoordinate2D
    
    var title: String? {
        return locationName
    }
    
    var subtitle: String? {
        return "\(weather) and \(temp) degrees"
    }
    
    //MARK: - Initialization
    init(locationName: String, weather: String, temp: Float, coordinate: CLLocationCoordinate2D) {
        self.locationName = locationName
        self.weather = weather
        self.temp = temp
        self.coordinate = coordinate
        
        super.init()
    }
}
