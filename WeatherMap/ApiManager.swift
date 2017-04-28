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

/**
 * Decided to use URLSession insted of a CocoaPod like AlamoFire as I didn't need to make extensive 
 * HTTP calls besides a singular GET method, and I thought it would be a good practice to 
 * learn how to implement this myself.
 */

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
    
    /** 
     * In reading up on documentation and examples, this can also be structured to handle different
     * HTTP methods. I thought structuring it in this way would be overkill for this project,
     * however, so I coded it in a way that is to be used implicitly with GET requests.
     *
     * Completion handlers are specified to run on the main thread as well, since MapView
     * will not update annotations from the background.
    */
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
