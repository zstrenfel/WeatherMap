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

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate, MKMapViewDelegate, UISearchBarDelegate {
    
    //MARK: - Properties
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var currentLocationButton: UIButton!
    
    var locationManager: CLLocationManager!
    let REGION_RADIUS: CLLocationDistance = 5000
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var weatherHistory: [String:[WeatherHistory]] = [:]
    var sections: [String] = []
    
    var currentWeather: WeatherHistory? = nil
    
    private let IS_ADMIN = true
    
    //MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        
        mapView.delegate = self
        
        tableView.tableFooterView = UIView()
        
        currentLocationButton.layer.cornerRadius = 10
        currentLocationButton.isHidden = true
        currentLocationButton.alpha = 0.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchWeatherHistory()
        self.tableView.reloadData()
    }
    
    // MARK: Map View
    func centerMap(on location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, REGION_RADIUS, REGION_RADIUS)
        mapView.setRegion(coordinateRegion, animated: true)
        self.getWeatherInfo(for: location)
    }
    
    func getWeatherInfo(for location: CLLocation) {
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
            
            //clear all existing annotations
            if (self.mapView.annotations.count > 0) {
                self.mapView.removeAnnotations(self.mapView.annotations)
            }
            
            self.mapView.addAnnotation(annotation)
            self.mapView.selectAnnotation(self.mapView.annotations[0], animated: true)
            self.saveWeatherHistory(for: weather)
        } else {
            log.debug("Wrong data type: \(String(describing: data))")
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
    
    //Used to determine if currentLocationButton should be set to visible or not
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if let userLocation = locationManager.location {
            if (!self.locationVisibleInMap(location: userLocation)) {
                self.showReturnButton()
            } else {
                self.hideReturnButton()
            }
        }
    }
    
    /**
     * Returns Bool indicating whether the map view currently has the
     * users location within it's bounds.
    */
    func locationVisibleInMap(location: CLLocation) -> Bool {
        let center = mapView.region.center
        let regionSpan = mapView.region.span
        let latDelta = regionSpan.latitudeDelta
        let lonDelta = regionSpan.longitudeDelta
        
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        
        return lat < (center.latitude + latDelta) && lat > (center.latitude - latDelta) &&
            lon < (center.longitude + lonDelta) && lon > (center.longitude - lonDelta)
    }
    
    func showReturnButton() {
        self.currentLocationButton.isHidden = false
        UIView.animate(withDuration: 0.5, animations: {
            self.currentLocationButton.alpha = 0.8
        })
    }
    
    func hideReturnButton() {
        UIView.animate(withDuration: 0.5, animations: {
            self.currentLocationButton.alpha = 0.0
        }, completion: { completed in
            if completed {
                self.currentLocationButton.isHidden = true
            }
        })
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
    
    // Will center the map on cell's location if it is not our current location.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! WeatherHistoryTableViewCell
        let location = CLLocation(latitude: cell.lat!, longitude: cell.lon!)
        
        if (!locationVisibleInMap(location: location)) {
            self.centerMap(on: location)
        }
    }
    
    /**
     * Presumes the success of a weatherHistory being created. Less resource heavy than re-fetching
     * all weatherhistories everytime the users navigates to a new location.
     */
    func addRow(with history: WeatherHistory) {
        let date = (history.created_at! as Date).dateString
        if !sections.contains(date) {
            sections.append(date)
            self.weatherHistory[date] = [history]
            self.tableView.insertSections([0], with: .top)
        } else {
            self.weatherHistory[date]!.insert(history, at: 0)
            let indexPath = IndexPath(row: 0, section: 0)
            self.tableView.insertRows(at: [indexPath], with: .top)
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
        centerMap(on: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        log.error(error)
    }
    
    //MARK: - Core Data
    func fetchWeatherHistory() {
        do {
            self.weatherHistory = [:]
            self.sections = []
            var weatherHistory: [WeatherHistory] = try context.fetch(WeatherHistory.fetchRequest()) as! [WeatherHistory]
            weatherHistory.sort { $0.created_at?.compare($1.created_at! as Date) == .orderedDescending }
            for history in weatherHistory {
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
        
        //updates table with previous weather history if need be
        if currentWeather != nil {
            self.addRow(with: currentWeather!)
        }
        currentWeather = history
    }
    
    //MARK: - Search Bar Delegate
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        dismiss(animated: true, completion: nil)
        
        let localSearchRequet = MKLocalSearchRequest()
        localSearchRequet.naturalLanguageQuery = searchBar.text
        let localSearch = MKLocalSearch(request: localSearchRequet)
        
        localSearch.start { (response, error) in
            if response == nil{
                let alertController = UIAlertController(title: nil, message: "Place Not Found", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
                self.present(alertController, animated: true, completion: nil)
                return
            } else {
                let location = CLLocation(latitude: response!.boundingRegion.center.latitude, longitude: response!.boundingRegion.center.longitude)
                self.centerMap(on: location)
            }
        }
    }
    
    // MARK: - Actions
    // Segues to admin tools
    override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) {
        if IS_ADMIN {
            self.performSegue(withIdentifier: "showAdmin", sender: nil)
        }
    }
    
    @IBAction func returnToCurrentLocation(_ sender: UIButton) {
        centerMap(on: locationManager.location!)
    }
    
    @IBAction func showSearchBar(_ sender: UIBarButtonItem) {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = "Enter Location"
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.delegate = self
        present(searchController, animated: true, completion: nil)
    }
}

