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
import CoreData

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate, MKMapViewDelegate {
    
    //MARK: - Properties
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var currentLocationButton: UIButton!
    
    var locationManager: CLLocationManager!
    let REGION_RADIUS: CLLocationDistance = 5000
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var weatherHistory: [String:[WeatherHistory]] = [:]
    var sections: [String] = []
    
    let IS_ADMIN = true
    
    //MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        
        mapView.delegate = self
        
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchWeatherHistory()
        self.tableView.reloadData()
    }
    
    
    func fetchWeatherHistory() {
        do {
            var weatherHistory: [WeatherHistory] = try context.fetch(WeatherHistory.fetchRequest()) as! [WeatherHistory]
            log.debug(weatherHistory)
            weatherHistory.sort { $0.created_at?.compare($1.created_at! as Date) == .orderedDescending }
            _ = weatherHistory.map { history in
                let date = (history.created_at! as Date).dateString
                if !sections.contains(date) {
                    sections.append(date)
                    self.weatherHistory[date] = []
                }
                self.weatherHistory[date]!.append(history)
            }
        } catch {
            log.error("Could not fetch weather history from core data")
        }
    }
    
    func saveWeatherHistory(for weather: Weather) {
        let history = WeatherHistory(context: context)
        history.setValue(Date(), forKey: "created_at")
        history.setValue(weather.lat, forKey: "lat")
        history.setValue(weather.lon, forKey: "lon")
        history.setValue(weather.name, forKey: "location_name")
        history.setValue(weather.humidity, forKey: "humidity")
        history.setValue(weather.temp, forKey: "temp")
        history.setValue(weather.weather, forKey: "weather")
        
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }
    
    // MARK: Map View
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, REGION_RADIUS, REGION_RADIUS)
        mapView.setRegion(coordinateRegion, animated: true)
        self.getWeatherInfo(location: location)
    }
    
    func getWeatherInfo(location: CLLocation) {
        var params: [String: Any] = [:]
        params["lat"] = location.coordinate.latitude
        params["lon"] = location.coordinate.longitude
        params["units"] = Units.imperial.rawValue
        
        ApiManager.shared.getWeather(with: params, onComplete: self.handleWeatherInfo)
    }
    
    func handleWeatherInfo(success: Bool, data: Any?) {
        if let weather = data as? Weather {
            let coordinate = CLLocationCoordinate2D(latitude: weather.lat!, longitude: weather.lon!)
            let annotation = WeatherLocation(locationName: weather.name!, weather: weather.weather!, temp: weather.temp!, humidity: weather.humidity!, coordinate: coordinate)
            
            if (self.mapView.annotations.count > 0) {
                self.mapView.removeAnnotations(self.mapView.annotations)
            }
            
            self.mapView.addAnnotation(annotation)
            self.mapView.selectAnnotation(self.mapView.annotations[0], animated: true)
            self.saveWeatherHistory(for: weather)
        } else {
            log.debug("something went wrong: \(String(describing: data))")
        }
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
                view.calloutOffset = CGPoint(x: -8, y: 0)
            }
            return view
        }
        return nil
    }
    
    //MARK: - Table View Data Source
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return sections[section]
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionKey = sections[section]
        return weatherHistory[sectionKey]!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "weatherHistoryCell") as! WeatherHistoryTableViewCell
        let sectionKey = self.sections[indexPath.section]
        let weatherHistory = self.weatherHistory[sectionKey]?[indexPath.row]
        cell.configureCell(with: weatherHistory!)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! WeatherHistoryTableViewCell
        let location = CLLocation(latitude: cell.lat!, longitude: cell.lon!)
        if location != locationManager.location! {
            self.centerMapOnLocation(location: location)
        }
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
    
    // MARK: - Actions
    override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) {
        if IS_ADMIN {
            self.performSegue(withIdentifier: "showAdmin", sender: nil)
        }
    }
    
    @IBAction func returnToCurrentLocation(_ sender: UIButton) {
        centerMapOnLocation(location: locationManager.location!)
    }
}

