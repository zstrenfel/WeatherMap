//
//  ViewController.swift
//  WeatherMap
//
// MapKit Functionality based off of:https://www.raywenderlich.com/90971/introduction-mapkit-swift-tutorial
//
//  Created by Zach Strenfel on 4/25/17.
//  Copyright © 2017 Zach Strenfel. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import XCGLogger

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate, MKMapViewDelegate {

    //MARK: - Properties
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    
    var locationManager: CLLocationManager!
    var weatherCells = ["Springfield", "Somewhere"]
    let REGION_RADIUS: CLLocationDistance = 2000
    
    var currentWeather: Weather? = nil {
        didSet {
            addWeatherLocationToMap(with: currentWeather!)
        }
    }
    
    var currCoords: CLLocationCoordinate2D? = nil
    
    //MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()

        locationManager.requestLocation()
        
        mapView.delegate = self
    }
    
    // MARK: Map View
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, REGION_RADIUS, REGION_RADIUS)
        mapView.setRegion(coordinateRegion, animated: true)
        ApiManager.shared.getWeather(for: location.coordinate, onComplete: handleWeatherInfo)
    }
    
    func handleWeatherInfo(success: Bool,info: Weather?) {
        if let weather = info {
            self.currentWeather = weather
        }
    }
    
    func addWeatherLocationToMap(with weather: Weather) {
        let annotation = WeatherLocation(locationName: weather.name!, weather: weather.weather!, temp: weather.temp!, coordinate: (locationManager.location?.coordinate)!)
        
        self.mapView.addAnnotation(annotation)
        self.mapView.selectAnnotation(annotation, animated: true)
    }
    
    //MARK: - Map View Delegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? WeatherLocation {
            let identifier = "pin"
            var view: MKPinAnnotationView
            if let dequeued = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView {
                dequeued.annotation = annotation
                view = dequeued
            } else {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.isSelected = true
                view.calloutOffset = CGPoint(x: -5, y: 5)
            }
            return view
        }
        return nil
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
        currCoords = location.coordinate
        centerMapOnLocation(location: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        log.error(error)
    }
}

