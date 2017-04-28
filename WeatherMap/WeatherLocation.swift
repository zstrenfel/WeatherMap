//
//  WeatherLocation.swift
//  WeatherMap
//
//  Created by Zach Strenfel on 4/26/17.
//  Copyright © 2017 Zach Strenfel. All rights reserved.
//

import Foundation
import MapKit

//Class that extends MKAnnotation to be used as annotations for the MapView
class WeatherLocation: NSObject, MKAnnotation {
    
    //MARK: - Properties
    let locationName: String
    let weather: String
    let temp: Int
    let humidity: Int
    let coordinate: CLLocationCoordinate2D
    
    var title: String? {
        return locationName
    }
    
    var subtitle: String? {
        return "\(weather), \(temp)°, humidity at \(humidity)%"
    }
    
    //MARK: - Initialization
    init(locationName: String, weather: String, temp: Float, humidity: Int, coordinate: CLLocationCoordinate2D) {
        self.locationName = locationName
        self.weather = weather
        self.temp = Int(temp)
        self.humidity = Int(humidity)
        self.coordinate = coordinate
        
        super.init()
    }
}
