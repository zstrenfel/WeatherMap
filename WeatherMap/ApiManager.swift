//
//  ApiManager.swift
//  WeatherMap
//
//  Created by Zach Strenfel on 4/25/17.
//  Copyright © 2017 Zach Strenfel. All rights reserved.
//

import Foundation
import MapKit

class ApiManager {
    
    static let shared = ApiManager()
    
    fileprivate let HOST = "api.openweathermap.org"
    fileprivate let baseURL = "/data/2.5/weather?"
    fileprivate let defaultSession = URLSession(configuration: .default)
    
    
    func getWeather(for coordinate: CLLocationCoordinate2D) {
        let queryString = "lat=\(coordinate.latitude)&lon=\(coordinate.longitude)"
        
        let url = URL(string: HOST + baseURL + queryString)
        let request = URLRequest(url: url!)
        let task = defaultSession.dataTask(with: request, completionHandler: { (data, response, error) in
            log.debug(data)
            log.debug(response)
            log.debug(error)
        })
        task.resume()
    }
}
