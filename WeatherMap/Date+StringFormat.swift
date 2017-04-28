//
//  File.swift
//  WeatherMap
//
//  Created by Zach Strenfel on 4/27/17.
//  Copyright © 2017 Zach Strenfel. All rights reserved.
//

import Foundation

/**
 * Decided to create an extension of date as these functions were being used quiet
 * often, and I would rather they not clutter up other controllers. 
 */
extension Date {
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}
