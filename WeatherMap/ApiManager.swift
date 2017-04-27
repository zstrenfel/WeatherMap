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

enum Units: String {
    case imperial = "imperial"
    case metric = "metric"
}

class ApiManager {
    //Singleton instance of ApiManager
    static let shared = ApiManager()
    
    fileprivate let HOST = "http://api.openweathermap.org"
    fileprivate let API_KEY = "77f5a3424a8711343cbb3094bc8337d3"
    
    typealias CompletionHandler = (Bool, Any?) -> Void
    
    func getWeather(with params: [String: Any], onComplete: @escaping CompletionHandler) {
        let baseURL = "/data/2.5/weather"
        let query = self.parametersToQueryString(with: params)
        let url = URL(string: HOST + baseURL + query)
        let request = URLRequest(url: url!)
        
        self.dataTask(for: request, onComplete: onComplete)
        
    }
    
    fileprivate func parametersToQueryString(with params: [String: Any]) -> String {
        var query = ""
        for (i, key) in params.keys.enumerated() {
            let val = params[key]
            query += i == 0 ? "?" : "&"
            query += "\(key)=\(val!)"
        }
        query += "&APPID=\(API_KEY)"
        return query
    }
    
    fileprivate func dataTask(for request: URLRequest, onComplete: @escaping CompletionHandler) {
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
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
