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
    
    fileprivate let HOST = "http://api.openweathermap.org"
    fileprivate let baseURL = "/data/2.5/weather?"
    fileprivate let defaultSession = URLSession(configuration: .default)
    //Using Open Weather API
    fileprivate let API_KEY = "77f5a3424a8711343cbb3094bc8337d3"
    
    typealias completionHandler = ((Bool, Any?) -> Void)
    
    func getWeather(for coordinate: CLLocationCoordinate2D, onComplete: @escaping completionHandler) {
        let queryString = "lat=\(Int(coordinate.latitude))&lon=\(Int(coordinate.longitude))&APPID=\(API_KEY)"
        
        let url = URL(string: HOST + baseURL + queryString)
        let request = URLRequest(url: url!)
        let task = defaultSession.dataTask(with: request, completionHandler: { (data, response, error) in
            var json: Any? = nil
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    onComplete(false, json)
                } else {
                    json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    onComplete(true, json)
                }
            }
        })
        task.resume()
    }
}
