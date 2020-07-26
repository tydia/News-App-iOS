//
//  searchTVC.swift
//  CSCI571-NewsApp
//
//  Created by Tong Wang on 5/3/20.
//  Copyright © 2020 Tong Wang. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SwiftSpinner

class searchTVC: UITableViewController, UISearchBarDelegate {
    var searchSeggustions = [String]()
    var numSegguestions: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numSegguestions == 0 ? 0 : numSegguestions
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchCell", for: indexPath)
        cell.textLabel?.text = searchSeggustions[indexPath.row]
        return cell
    }
    
    // MARK: show search results
    // on table cell tap, instantiate search results view controller
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currCellInd = indexPath.row
        let selectedSearch = self.searchSeggustions[currCellInd]
        SwiftSpinner.show("Loading Search results..")
        let searchResultsView = storyboard!.instantiateViewController(withIdentifier: "searchResults") as! searchResultsVC
        self.presentingViewController?.navigationController?.pushViewController(searchResultsView, animated: true)
        searchResultsView.queryString = selectedSearch
        
        self.searchSeggustions.removeAll()
        self.tableView.isHidden = true
    }

    func getBingSuggestions(_ searchText: String) {
        let autoSuggestUrl = "https://testautosugge.cognitiveservices.azure.com/bing/v7.0/suggestions?q=\(searchText.lowercased())".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let header: HTTPHeaders = [
          "Ocp-Apim-Subscription-Key": "21e40097daa54c5e8cdfc2c4b4114be1"
        ]

        // only make request if user typed three or more chars
        if searchText.count > 2 {
            Alamofire.request(autoSuggestUrl, headers: header)
                .validate(statusCode: 200..<300)
                .validate(contentType: ["application/json"])
                .responseJSON { response in
                    switch response.result {
                    case .success:
                        if let json = response.data {
                            do{
                                var tempSuggest = [String]()
                                let data = try JSON(data: json)
                                self.numSegguestions = data["suggestionGroups"][0]["searchSuggestions"].count
                                for i in 0..<self.numSegguestions {
                                    tempSuggest.append("\(data["suggestionGroups"][0]["searchSuggestions"][i]["displayText"])")
                                }
                                self.searchSeggustions = tempSuggest
                                self.tableView.reloadData()
                            }
                            catch{
                                print("Some errors occured when parsing home news response JSON")
                            }
                        }
                    case let .failure(error):
                        print(error)
                    }
                }
        }
    }

}

// extend updateSearchResults with Bing auto suggest
extension searchTVC: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    let searchBar = searchController.searchBar
    getBingSuggestions(searchBar.text!)
  }
}
