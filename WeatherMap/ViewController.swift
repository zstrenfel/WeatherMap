//
//  ViewController.swift
//  WeatherMap
//
//  Created by Zach Strenfel on 4/25/17.
//  Copyright © 2017 Zach Strenfel. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import XCGLogger

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate {

    //MARK: - Properties
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    
    var locationManager: CLLocationManager!
    var weatherCells = ["Springfield", "Somewhere"];
    let REGION_RADIUS: CLLocationDistance = 1000
    
    //MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()

        locationManager.requestLocation()
    }
    
    //MARK: - Map View
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, REGION_RADIUS, REGION_RADIUS)
        mapView.setRegion(coordinateRegion, animated: true)
        ApiManager.shared.getWeather(for: location.coordinate, onComplete: <#ApiManager.completionHandler#>)
    }
    
    func gotWeather(success: Bool, data: Any) {
        
    }
    
    //MARK: - Table View Data Source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return weatherCells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "weatherHistoryCell") as! WeatherHistoryTableViewCell
        cell.locationLabel.text = self.weatherCells[indexPath.row]
        return cell
    }
    
    //MARK: - Location Manager Delegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            log.error("no location information given")
            return
        }
        centerMapOnLocation(location: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        log.error(error)
    }
}

