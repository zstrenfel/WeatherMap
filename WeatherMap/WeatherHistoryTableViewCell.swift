//
//  WeatherHistoryTableViewCell.swift
//  WeatherMap
//
//  Created by Zach Strenfel on 4/25/17.
//  Copyright © 2017 Zach Strenfel. All rights reserved.
//

import UIKit

class WeatherHistoryTableViewCell: UITableViewCell {

    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var weatherLabel: UILabel!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    var lat: Double? = nil
    var lon: Double? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureCell(with weather: WeatherHistory) {
        locationLabel.text = weather.location_name
        humidityLabel.text = "\(weather.humidity)%"
        tempLabel.text = "\(Int(weather.temp))°"
        weatherLabel.text = weather.weather
        lat = weather.lat
        lon = weather.lon
        timeLabel.text = (weather.created_at! as Date).timeString
    }

}
