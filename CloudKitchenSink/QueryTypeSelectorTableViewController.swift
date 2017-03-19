//
//  QueryTypeSelectorTableViewController.swift
//  CloudKitchenSink
//
//  Created by Guilherme Rambo on 12/03/17.
//  Copyright © 2017 Guilherme Rambo. All rights reserved.
//

import UIKit

class QueryTypeSelectorTableViewController: UITableViewController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier, let queryType = QueryType(rawValue: identifier) else {
            fatalError("Unknown query type \(String(describing: segue.identifier))")
        }
        
        guard let destination = segue.destination as? QueryTableViewController else {
            fatalError("Query type segue destination must be a QueryTableViewController")
        }
        
        destination.queryType = queryType
    }

}
