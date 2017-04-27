//
//  File.swift
//  WeatherMap
//
//  Created by Zach Strenfel on 4/27/17.
//  Copyright © 2017 Zach Strenfel. All rights reserved.
//

import Foundation

extension Date {
    var stringFormat: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}
