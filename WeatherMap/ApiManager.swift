//
//  ApiManager.swift
//  WeatherMap
//
//  Created by Zach Strenfel on 4/25/17.
//  Copyright © 2017 Zach Strenfel. All rights reserved.
//

import Foundation
import MapKit
import ObjectMapper

class ApiManager {
    //Singleton instance of ApiManager
    static let shared = ApiManager()
    
    fileprivate let HOST = "http://api.openweathermap.org"
    fileprivate let baseURL = "/data/2.5/weather?"
    //Using Open Weather API
    fileprivate let API_KEY = "77f5a3424a8711343cbb3094bc8337d3"
    
    
    func getWeather(for coordinate: CLLocationCoordinate2D, onComplete: @escaping (Bool, Weather?) -> Void) {
        let session = URLSession(configuration: .default)
        let queryString = "lat=\(Int(coordinate.latitude))&lon=\(Int(coordinate.longitude))&APPID=\(API_KEY)"
        
        let url = URL(string: HOST + baseURL + queryString)
        let request = URLRequest(url: url!)
        
        session.dataTask(with: request, completionHandler: { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    onComplete(false, nil)
                } else {
                    let json = String(data: data!, encoding: String.Encoding.utf8)!
                    let weatherInfo = Mapper<Weather>().map(JSONString: json)
                    onComplete(true, weatherInfo)
                }
            }
        }).resume()
    }
}
