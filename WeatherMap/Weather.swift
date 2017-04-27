//
//  Weather.swift
//  WeatherMap
//
//  Created by Zach Strenfel on 4/26/17.
//  Copyright © 2017 Zach Strenfel. All rights reserved.
//

import Foundation
import ObjectMapper

class Weather: Mappable {
    var lat: Double?
    var lon: Double?
    var weather: String? 
    var temp: Float?
    var name: String?
    var humidity: Int?
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        lat         <- map["coord.lat"]
        lon         <- map["coord.lon"]
        weather     <- map["weather.0.main"]
        temp        <- map["main.temp"]
        humidity    <- map["main.humidity"]
        name        <- map["name"]
    }
}
