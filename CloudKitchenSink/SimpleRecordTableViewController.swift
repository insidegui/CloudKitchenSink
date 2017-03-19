//
//  SimpleRecordTableViewController.swift
//  CloudKitchenSink
//
//  Created by Guilherme Rambo on 05/03/17.
//  Copyright © 2017 Guilherme Rambo. All rights reserved.
//

import UIKit
import CloudKit
import CoreLocation

enum MovieKey: String {
    case title
    case releaseDate
    case location
    case rating
}

extension CKRecord {
    
    subscript(key: MovieKey) -> Any? {
        get {
            return self[key.rawValue]
        }
        set {
            self[key.rawValue] = newValue as? CKRecordValue
        }
    }
    
}

extension String {
    
    init?(_ placemark: CLPlacemark) {
        guard let country = placemark.country, let locality = placemark.locality else { return nil }
        
        self = "\(locality), \(country)"
    }
    
}

class SimpleRecordTableViewController: UITableViewController {

    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var dateField: UITextField!
    @IBOutlet weak var locationField: UITextField!
    @IBOutlet weak var ratingSlider: UISlider!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var record = CKRecord(recordType: "Movie")
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func titleFieldAction(_ sender: Any) {
        guard let title = titleField.text else { return }
        
        record[.title] = title
    }
    
    @IBAction func releaseDateFieldAction(_ sender: Any) {
        guard let dateString = dateField.text else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = formatter.date(from: dateString) else { return }
        
        record[.releaseDate] = date
    }
    
    @IBAction func locationFieldAction(_ sender: Any) {
        guard let locationString = locationField.text else { return }
        
        CLGeocoder().geocodeAddressString(locationString) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil else { return }
            
            self.record[.location] = placemark.location
            
            DispatchQueue.main.async {
                self.locationField.text = String(placemark)
            }
        }
    }
    
    @IBAction func ratingSliderAction(_ sender: Any) {
        let value = Int(ceil(ratingSlider.value))
        
        record[.rating] = value
    }
    
    @IBAction func save(_ sender: Any) {        
        saveButton.isEnabled = false
        saveButton.isHidden = true
        activityIndicator.startAnimating()
        
        container.publicCloudDatabase.save(record) { [unowned self] _, error in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.saveButton.isEnabled = true
                self.saveButton.isHidden = false
                
                if let error = error {
                    let alert = UIAlertController(title: "CloudKit error", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    self.clear()
                }
            }
        }
    }
    
    private func clear() {
        titleField.text = nil
        dateField.text = nil
        locationField.text = nil
        ratingSlider.value = 0
        
        record = CKRecord(recordType: "Movie")
        
        _ = titleField.becomeFirstResponder()
    }

}
