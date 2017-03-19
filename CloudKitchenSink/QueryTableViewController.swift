//
//  QueryTableViewController.swift
//  CloudKitchenSink
//
//  Created by Guilherme Rambo on 12/03/17.
//  Copyright © 2017 Guilherme Rambo. All rights reserved.
//

import UIKit
import CloudKit
import CoreLocation

enum QueryType: String {
    
    case all
    case title
    case location
    
    var title: String {
        switch self {
        case .all:
            return "All Records"
        case .title:
            return "Search by Title"
        case .location:
            return "Search by Location"
        }
    }
    
}

final class QueryTableViewController: UITableViewController {
    
    @IBOutlet weak var searchContainer: UIStackView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    
    fileprivate var currentLocation: CLLocation? {
        didSet {
            DispatchQueue.main.async {
                self.search(self)
            }
        }
    }
    
    fileprivate var movies: [CKRecord] = [] {
        didSet {
            tableView.reloadSections([0], with: .automatic)
        }
    }
    
    var queryType: QueryType? {
        didSet {
            guard let queryType = queryType else { return }
            
            title = queryType.title
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let queryType = queryType else { return }
        
        if queryType != .title {
            tableView.tableHeaderView = nil
            search(self)
        } else {
            _ = textField.becomeFirstResponder()
        }
    }
    
    private lazy var locationManager: CLLocationManager = {
        let m = CLLocationManager()
        
        m.distanceFilter = kCLDistanceFilterNone
        m.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        m.delegate = self
        
        return m
    }()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    private func predicate(with title: String) -> NSPredicate {
        return NSPredicate(format: "self contains %@", title)
    }
    
    private func predicate(closeTo location: CLLocation, radius: Float = 500.0) -> NSPredicate {
        return NSPredicate(format: "distanceToLocation:fromLocation:(location, %@) < %f", location, radius)
    }
    
    private func predicateForAll() -> NSPredicate {
        return NSPredicate(value: true)
    }
    
    private var currentOperation: CKDatabaseOperation?
    
    fileprivate func showLocationAlert() {
        let alert = UIAlertController(title: "No Location", message: "Sorry, I don't know your location", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func search(_ sender: Any) {
        guard let queryType = self.queryType else { return }
        
        currentOperation?.cancel()
        
        let predicate: NSPredicate
        
        switch queryType {
        case .all:
            predicate = self.predicateForAll()
        case .title:
            predicate = self.predicate(with: textField.text ?? "")
        case .location:
            if let location = currentLocation {
                predicate = self.predicate(closeTo: location)
            } else {
                // wait for the location to become available
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                return
            }
        }
        
        let query = CKQuery(recordType: "Movie", predicate: predicate)
        
        self.perform(query: query) { [weak self] movieRecords, error in
            self?.movies = movieRecords
        }
    }
    
    private var fetchedRecords: [CKRecord] = []
    
    private func perform(query: CKQuery, inputCursor: CKQueryCursor? = nil, completion: @escaping ([CKRecord], Error?) -> Void) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        searchButton?.isEnabled = false
        
        let operation: CKQueryOperation
        
        if let inputCursor = inputCursor {
            operation = CKQueryOperation(cursor: inputCursor)
        } else {
            operation = CKQueryOperation(query: query)
        }
        
        operation.recordFetchedBlock = { [weak self] record in
            self?.fetchedRecords.append(record)
        }
        
        operation.queryCompletionBlock = { [weak self] cursor, error in
            guard let welf = self else { return }
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                welf.searchButton?.isEnabled = true
                
                welf.currentOperation = nil
                
                if let cursor = cursor {
                    welf.perform(query: query, inputCursor: cursor, completion: completion)
                } else {
                    completion(welf.fetchedRecords, nil)
                    welf.fetchedRecords = []
                }
            }
        }
        
        container.publicCloudDatabase.add(operation)
        
        currentOperation = operation
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "movie")
        
        cell?.textLabel?.text = movies[indexPath.row]["title"] as? String ?? ""
        
        if let date = movies[indexPath.row]["releaseDate"] as? Date {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            cell?.detailTextLabel?.text = formatter.string(from: date)
        }
        
        return cell ?? UITableViewCell()
    }
    
}

extension QueryTableViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        self.currentLocation = location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.showLocationAlert()
        }
    }
    
}
