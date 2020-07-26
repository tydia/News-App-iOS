//
//  TrendingViewController.swift
//  CSCI571-NewsApp
//
//  Created by Tong Wang on 4/21/20.
//  Copyright © 2020 Tong Wang. All rights reserved.
//

import UIKit
import Charts
import Alamofire
import SwiftyJSON

class TrendingViewController: UIViewController, UITextFieldDelegate {
    let trendURL = "http://myiosnewsappbackend.us-east-1.elasticbeanstalk.com/trending?q="
    
    @IBOutlet weak var searchTextfield: UITextField!
    @IBOutlet weak var trendLineChartView: LineChartView!
    
    var values = [Int]()
    var userInputText:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchTextfield.delegate = self
        setupNavbar()
        fetchTrending("Coronavirus")
    }
    
    // MARK: textfield delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // hide keyboard
        textField.resignFirstResponder()
        if userInputText != "" {
            fetchTrending(userInputText)
        }
        
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        
        self.userInputText = NSString(string: searchTextfield.text!).replacingCharacters(in: range, with: string)
        return true
    }
    
    func fetchTrending (_ query:String) {
        let escapeUrl = (trendURL + query).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        Alamofire.request(escapeUrl)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                switch response.result {
                case .success:
                    if let json = response.data {
                        do{
                            self.values.removeAll()
                            let data = try JSON(data: json)
                            if let dataArr = data.array {
                                for i in 0..<dataArr.count {
                                    if let aValue = dataArr[i].int {
                                        self.values.append(aValue)
                                    } else {
                                        print("Error parsing value entry")
                                    }
                                }
                            } else {
                                print("Error parsing values array")
                            }
                            // handle no trend result case
                            // i do it this way to make UI consistent (i.e show a chart no matter what)
                            if self.values.count == 0 {
                                for _ in 0..<48 {
                                    self.values.append(0)
                                }
                            }
                            self.updateChart(query)
                        }
                        catch{
                            print("Some errors occured when parsing trend valus JSON array")
                        }
                    }
                case let .failure(error):
                    print(error)
                }
            }
    }

    func setupNavbar () {
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    func updateChart (_ query:String) {
        var chartEntry = [ChartDataEntry]()
        for i in 0..<values.count {
            let value = ChartDataEntry(x: Double(i), y: Double(values[i]))
            
            chartEntry.append(value)
        }
        
        let line = LineChartDataSet(entries: chartEntry, label: "Trending Chart for \(query)")
        // customize styles
        line.colors = [.systemBlue]
        line.circleRadius = CGFloat.init(5.0)
        line.circleColors = [.systemBlue]
        line.circleHoleColor = .systemBlue
        // present data
        let data = LineChartData()
        data.addDataSet(line)
        

        // use int for y values instead of double
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        data.setValueFormatter(DefaultValueFormatter(formatter:formatter))

        trendLineChartView.data = data
        
    }
    
}
