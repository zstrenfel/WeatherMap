//
//  Weather.swift
//  WeatherMap
//
//  Created by Zach Strenfel on 4/26/17.
//  Copyright © 2017 Zach Strenfel. All rights reserved.
//

import Foundation
import ObjectMapper

class WeatherInfo: Mappable {
    var coord: Coord?
    var main: Main?
    var name: String?
    var weather: [Any]?
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        coord       <- map["coord"]
        main        <- map["main"]
        name        <- map["name"]
        weather     <- map["weather"]
    }
}

struct Coord {
    var lat: Int?
    var lon: Int?
    
    init?(map: Map) {}
    
    mutating func mapping(map: Map) {
        lat         <- map["lat"]
        lon         <- map["lon"]
    }
    
}


struct Main {
    var temp: Float?
    var humidity: Int?
    var pressure: Int?
    var minTemp: Float?
    var maxTemp: Float?
    
    init?(map: Map) {}
    
    mutating func mapping(map: Map) {
        temp        <- map["temp"]
        humidity    <- map["humidity"]
        pressure    <- map["pressure"]
        minTemp     <- map["temp_min"]
        maxTemp     <- map["temp_max"]
    }
}
