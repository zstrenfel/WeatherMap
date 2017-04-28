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
    var weatherHistory: [WeatherHistory] = []
    var currentWeather: WeatherHistory? = nil
    //how many weather history objects should be displayed
    let HISTORY_LIMIT = 5
    
    private let IS_ADMIN = true
    
    //MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.requestLocation()
        
        self.mapView.delegate = self
        
        self.tableView.tableFooterView = UIView()
        
        self.currentLocationButton.layer.cornerRadius = 10
        self.currentLocationButton.isHidden = true
        self.currentLocationButton.alpha = 0.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.currentWeather = nil
        self.fetchWeatherHistory()
        self.tableView.reloadData()
    }
    
    // MARK: Map View
    func centerMap(on location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, REGION_RADIUS, REGION_RADIUS)
        self.mapView.setRegion(coordinateRegion, animated: true)
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
            if self.mapView.annotations.count > 0 {
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
            if let dequeued = self.mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView {
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
        if let userLocation = self.locationManager.location {
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
        let center = self.mapView.region.center
        let regionSpan = self.mapView.region.span
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
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.weatherHistory.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "weatherHistoryCell") as! WeatherHistoryTableViewCell
        let weatherHistory = self.weatherHistory[indexPath.row]
        cell.configureCell(with: weatherHistory)
        return cell
    }
    
    // Will center the map on cell's location if it is not our current location.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = self.tableView.cellForRow(at: indexPath) as! WeatherHistoryTableViewCell
        let location = CLLocation(latitude: cell.lat!, longitude: cell.lon!)
        
        if (!self.locationVisibleInMap(location: location)) {
            self.centerMap(on: location)
        }
    }
    
    /**
     * Presumes the success of a weatherHistory being created. Less resource heavy than re-fetching
     * all weatherhistories everytime the users navigates to a new location.
     */
    func addRow(with history: WeatherHistory) {
        self.tableView.beginUpdates()
        log.debug(self.weatherHistory.count)
        if (self.weatherHistory.count >= self.HISTORY_LIMIT) {
            for i in 0..<(self.weatherHistory.count - (self.HISTORY_LIMIT - 1)) {
                let row = (self.HISTORY_LIMIT - 1) + (1 * i)
                self.tableView.deleteRows(at: [IndexPath(row: row, section: 0)], with: .top)
            }
            self.weatherHistory = Array(weatherHistory[0..<(self.HISTORY_LIMIT - 1)])
        }
        self.weatherHistory.insert(history, at: 0)
        self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
        self.tableView.endUpdates()
    }
    
    //MARK: - Location Manager Delegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            self.locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            log.error("no location information given")
            return
        }
        self.centerMap(on: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        log.error(error)
    }
    
    //MARK: - Core Data
    func fetchWeatherHistory() {
        do {
            let weatherFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "WeatherHistory")
            weatherFetchRequest.sortDescriptors = [NSSortDescriptor(key: "created_at", ascending: false)]
            weatherFetchRequest.fetchLimit = self.HISTORY_LIMIT
            self.weatherHistory = try context.fetch(weatherFetchRequest) as! [WeatherHistory]
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
        if self.currentWeather != nil {
            self.addRow(with: currentWeather!)
        }
        self.currentWeather = history
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
        if self.IS_ADMIN {
            self.performSegue(withIdentifier: "showAdmin", sender: nil)
        }
    }
    
    @IBAction func returnToCurrentLocation(_ sender: UIButton) {
        self.centerMap(on: locationManager.location!)
    }
    
    @IBAction func showSearchBar(_ sender: UIBarButtonItem) {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = "Enter Location"
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.delegate = self
        self.present(searchController, animated: true, completion: nil)
    }
}

