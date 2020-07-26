//
//  HomeViewController.swift
//  CSCI571-NewsApp
//
//  Created by Tong Wang on 4/20/20.
//  Copyright © 2020 Tong Wang. All rights reserved.
//

import UIKit
import SwiftSpinner
import Alamofire
import SwiftyJSON
import CoreLocation
import Toast_Swift

// stores one bookmark
// 1. id: for article bookmark status check
// 2. notMarked: bookcheck status. default would be true
// 3. cardInfo: a newsCard stuct, this is stored if notMarked is false
struct bookmark {
    var id: String
    var notMarked: Bool
    var cardInfo: newsCard
}

// global array of bookmarks that is used accross all views
var globalBookmarks = [bookmark]()

// helper class for bookmarking functionalities with UserDefaults
class bookmarkHelper {
    /******************************************/
    /*   set, get, remove image functionality */
    /******************************************/
    // save image for article id
    static func saveImage(url image:String, forKey id:String) {
        if image == "default-guardian" || image == "" {
            UserDefaults.standard.set(UIImage(named: "default-guardian")?.pngData(), forKey: id)
        } else {
            if let imageUrl = URL(string: image) {
                let imageData = NSData(contentsOf: imageUrl)
                // resize image to:
                // 1. minimize storage
                // 2. prevent image being to large to display
                let imageToSet = UIImage(data: imageData! as Data)!
                UserDefaults.standard.set(imageToSet.resizeShrink()?.pngData(), forKey: id)
            }
        }
    }
    
    // get image with article id
    static func getImage(forKey id:String) -> UIImage? {
        guard let imageData = UserDefaults.standard.data(forKey: id) else { return nil }
        let image = UIImage(data: imageData)
        return image
    }
    
    // remove image with article id
    static func removeImage(forKey id: String) {
        UserDefaults.standard.set(nil, forKey: id)
    }
    
    /******************************************/
    /* add, get, remove, search for bookmarks */
    /******************************************/
    // GET: gets current bookmarks array from user defaults
    static func getBookmarks() -> Array<newsCard>? {
        if let currBookmarks = UserDefaults.standard.value(forKey: "localBookmarks") as? Data {
            if let bookmarks = try? PropertyListDecoder().decode(Array<newsCard>.self, from: currBookmarks) {
                return bookmarks
            } else {
                return nil
            }
        }
        return nil
    }
    
    // SEARCH: search from an array of newsCards to check if an newsCard is bookmarked
    // this array of newsCards should be ALWAYS loaded from user defaults
    static func searchBookmarks(_ existingBookmarks:[newsCard], _ articleToFind: newsCard) -> Bool {
        for i in 0..<existingBookmarks.count {
            if existingBookmarks[i].articleID == articleToFind.articleID {
                return true
            }
        }
        return false
    }
    
    // ADD: get existing bookmarks array, search for input newsCard, if
    // it is not there, append to array and set back to user defaults. Otherwise
    static func addBookmark(_ article: newsCard) {
        if var existingBookmarks = getBookmarks() {
            let foundArticle = searchBookmarks(existingBookmarks, article)
            if !foundArticle {
                existingBookmarks.append(article)
                UserDefaults.standard.set(try? PropertyListEncoder().encode(existingBookmarks), forKey: "localBookmarks")
                saveImage(url: article.image ?? "default-guardian", forKey: article.articleID)
            }
        // edge case: no bookmarks stored yet
        } else {
            var tempArr = [newsCard]()
            tempArr.append(article)
            UserDefaults.standard.set(try? PropertyListEncoder().encode(tempArr), forKey: "localBookmarks")
        }
    }
    
    // REMOVE: get existing bookmarks, traverse it, keep only the ones that are not the input newsCard and set back to user defaults
    static func removeBookmark(_ article: newsCard) {
        if let existingBookmarks = getBookmarks() {
            var tempArr = [newsCard]()
            for i in 0..<existingBookmarks.count {
                if article.articleID != existingBookmarks[i].articleID {
                    tempArr.append(existingBookmarks[i])
                }
            }
            removeImage(forKey: article.articleID)
            UserDefaults.standard.set(try? PropertyListEncoder().encode(tempArr), forKey: "localBookmarks")
        } else {
            // should never happen
            print("failed to remove bookmark b/c it DNE")
        }
    }
    
    // this function is used to handle the problem that reusable cells
    // displays wrong bookmark status. It re-generates approporiate
    // globalBookmarks array with correct indecies.
    // it is called whenever:
    // 1. a news request was made (when view loads or pull down refreshed)
    // 2. user leaves current view then comes back (viewWillAppear)
    // This function is called for all views
    static func updateGlobalBookmarkStatus(_ allNews: [newsCard]) {
        // remove all bookmark global array
        globalBookmarks.removeAll()
        // re-generate that global array
        for i in 0..<allNews.count {
            // if user default is not empty, search article before setting
            if let currBookmarks = bookmarkHelper.getBookmarks() {
                let bookmarkFound = bookmarkHelper.searchBookmarks(currBookmarks, allNews[i])
                // if curr article id found in user defaults, set notMarked to false, meaning that the article was bookmarked
                if bookmarkFound {
                    globalBookmarks.append(bookmark(id: allNews[i].articleID, notMarked: false, cardInfo: allNews[i]))
                }
                // otherwise this article was not bookmarked
                else {
                    globalBookmarks.append(bookmark(id: allNews[i].articleID, notMarked: true, cardInfo: allNews[i]))
                }
            }
            // userdefault is empty, all articles are notMarked
            else {
                globalBookmarks.append(bookmark(id: allNews[i].articleID, notMarked: true, cardInfo: allNews[i]))
            }
        }
    }
    
}

// struct that stores news description. used for:
// 1. fetching news
// 2. storing as a bookmark to user defaults
struct newsCard: Codable {
    var image: String?
    var title: String
    var time: String
    var section: String
    var articleID: String
}

// this protocol is used for telling parent view from a cell that the bookmark button inside that cell istapped
protocol tableCellDelegate {
    func didTapBookmark(_ message: String)
}

// custom news card cell
class newsCardCell: UITableViewCell {
    @IBOutlet weak var c_image: UIImageView!
    @IBOutlet weak var c_title: UILabel!
    @IBOutlet weak var c_time: UILabel!
    @IBOutlet weak var c_section: UILabel!
    @IBOutlet weak var c_button: UIButton!
    
    var id = ""
    // declare delegate
    var delegate: tableCellDelegate?
    
    // no inits here b/c everything were defined at storyboard
    // awakeFromNib allow us to add more logics to existing design
    override func awakeFromNib() {
        super.awakeFromNib()
        c_image.layer.cornerRadius = 7
    }
    
    @IBAction func bookmarking(_ sender: UIButton) {
        var currBookmarkStatus:Bool
        for i in 0..<globalBookmarks.count {
            currBookmarkStatus = !globalBookmarks[i].notMarked
            if globalBookmarks[i].id == id {
                globalBookmarks[i].notMarked = currBookmarkStatus//notBookmarked
                let image = currBookmarkStatus ? UIImage(systemName: "bookmark") : UIImage(systemName: "bookmark.fill")
                c_button.setImage(image, for: .normal)
                
                // make corresponding toast
                let toastMessage = !currBookmarkStatus ? "Article Bookmarked. Check out the Bookmarks tab to view" : "Article Removed from Bookmarks"
                delegate?.didTapBookmark(toastMessage)
                
                // set/remove bookmark
                !currBookmarkStatus ? bookmarkHelper.addBookmark(globalBookmarks[i].cardInfo) : bookmarkHelper.removeBookmark(globalBookmarks[i].cardInfo)
            }
        }
        
    }
    
    override func prepareForReuse() {
        // invoke superclass implementation
        super.prepareForReuse()
        
        // forbid bookmark icon reuse. approporiate icon state are retrived from globalBookmarks
        self.c_button?.setImage(UIImage(systemName: "bookmark"), for: .normal)
    }
    
}

// MARK: custom weather cell
class weatherCell: UITableViewCell, CLLocationManagerDelegate {
    @IBOutlet weak var w_image: UIImageView!
    @IBOutlet weak var w_city: UILabel!
    @IBOutlet weak var w_temp: UILabel!
    @IBOutlet weak var w_state: UILabel!
    @IBOutlet weak var w_weather: UILabel!
    
    var locationManager: CLLocationManager?
    let weatherAPIKey: String = "239ab197c4983753df91baf85eb8e63f"
    
    // for converting state abbr to full state name
    // ref: https://stackoverflow.com/questions/31158998/clgeocoder-us-state-names-are-coming-as-a-short-codes
    let stateCodes = ["AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA",
                      "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD","MA",
                      "MI","MN","MS","MO","MT","NE","NV","NH","NJ","NM","NY",
                      "NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX",
                      "UT","VT","VA","WA","WV","WI","WY"]
    let fullStateNames = ["Alabama","Alaska","Arizona","Arkansas","California","Colorado",
                          "Connecticut","Delaware","District of Columbia","Florida",
                          "Georgia","Hawaii","Idaho","Illinois","Indiana","Iowa",
                          "Kansas","Kentucky","Louisiana","Maine","Maryland","Massachusetts",
                          "Michigan","Minnesota","Mississippi","Missouri","Montana","Nebraska",
                          "Nevada","New Hampshire","New Jersey","New Mexico","New York",
                          "North Carolina","North Dakota","Ohio","Oklahoma","Oregon","Pennsylvania",
                          "Rhode Island","South Carolina","South Dakota","Tennessee","Texas",
                          "Utah","Vermont","Virginia","Washington","West Virginia","Wisconsin","Wyoming"]

    func longStateName(_ stateCode:String) -> String {
        let dic = NSDictionary(objects: fullStateNames, forKeys:stateCodes as [NSCopying])
        return dic.object(forKey:stateCode) as? String ?? stateCode
    }
    
    
    // no inits here b/c everything were defined at storyboard
    // awakeFromNib allow us to add more logics to existing design
    override func awakeFromNib() {
        super.awakeFromNib()
        w_image.layer.cornerRadius = 7
        
        // get curr location
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
         print("Error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .denied {
            print("location access denied")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // .requestLocation will only pass one location to the locations array
        // hence we can access it by taking the first element of the array
        if let location = locations.first {
            
            // convert coordinates to city name
            let geoCoder = CLGeocoder()
            let location = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            geoCoder.reverseGeocodeLocation(location, completionHandler: {
                placemarks, error -> Void in

                // Place details
                guard let placeMark = placemarks?.first else { return }

                // City
                if let city = placeMark.subAdministrativeArea, let state = placeMark.administrativeArea {
                    let openWeatherUrl = "https://api.openweathermap.org/data/2.5/weather?q="
                                       // replace spaces with %20 for http request
                                       + city.replacingOccurrences(of: " ", with: "%20", options: .literal, range: nil)
                                       + "&units=metric&appid="
                                       + self.weatherAPIKey
                    
                    Alamofire.request(openWeatherUrl)
                        .validate(statusCode: 200..<300)
                        .validate(contentType: ["application/json"])
                        .responseJSON { response in
                            switch response.result {
                            case .success:
                                if let json = response.data {
                                    do{
                                        let data = try JSON(data: json)
                                        // get info to update weather subview's UI labels
                                        let w_temp_str:String = "\(data["main"]["temp"])".components(separatedBy: ("."))[0]+"\u{00B0}C"
                                        let w_state_str = self.longStateName(state)
                                        let w_weather_str = "\(data["weather"][0]["main"])"
                                        
                                        // update UI labels
                                        self.w_city.text = city
                                        self.w_state.text = w_state_str
                                        self.w_temp.text = w_temp_str
                                        self.w_weather.text = w_weather_str
                                        
                                        // update image according to w_weather
                                        switch w_weather_str {
                                        case "Clouds":
                                            self.w_image.image = UIImage(named: "cloudy_weather")
                                        case "Clear":
                                            self.w_image.image = UIImage(named: "clear_weather")
                                        case "Snow":
                                            self.w_image.image = UIImage(named: "snowy_weather")
                                        case "Rain":
                                            self.w_image.image = UIImage(named: "rainy_weather")
                                        case "Thunderstorm":
                                            self.w_image.image = UIImage(named: "thunder_weather")
                                        default:
                                            self.w_image.image = UIImage(named: "sunny_weather")
                                        }
                                        
                                        
                                    }
                                    catch{
                                        print("Some errors occured when parsing weather response JSON")
                                    }
                                    SwiftSpinner.hide()
                                }
                            case let .failure(error):
                                print(error)
                            }
                        }
                }
            })
        }
    }
}

// MARK: home view controller
class HomeViewController: UIViewController, UITableViewDelegate,  UITableViewDataSource, tableCellDelegate {
    func didTapBookmark(_ message:String) {
        self.view.makeToast(message, duration: 1.0)
    }
    
    var homeNews = [newsCard]()
    var newsImages = [UIImage]()
    
    let homeBackendUrl = "http://myiosnewsappbackend.us-east-1.elasticbeanstalk.com/home"

    @IBOutlet weak var tableView: UITableView!
    
    let refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        SwiftSpinner.show("Loading Home Page...")
        super.viewDidLoad()
//        UserDefaults.standard.removeObject(forKey: "localBookmarks")
        setupNavbar()
        setupTableView()
        fetchNews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        bookmarkHelper.updateGlobalBookmarkStatus(self.homeNews)
        tableView.reloadData()
    }
    
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        print("Selected item")
    }

    func setupNavbar () {
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let searchTableVC = storyboard!.instantiateViewController(withIdentifier: "searchTVC") as! searchTVC
        let searchController = UISearchController(searchResultsController: searchTableVC)
        searchController.searchResultsUpdater = searchTableVC
        searchController.searchBar.placeholder = "Enter keyword.."
        searchController.searchBar.delegate = searchTableVC
        
        navigationItem.searchController = searchController
        navigationController!.navigationBar.sizeToFit()
    }
    
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        refreshControl.addTarget(self, action: #selector(fetchNews), for: .valueChanged)
        tableView.addSubview(refreshControl)
    }

    @objc private func fetchNews() {
        Alamofire.request(homeBackendUrl)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                switch response.result {
                case .success:
                    if let json = response.data {
                        do{
                            self.homeNews.removeAll()
                            self.refreshControl.beginRefreshing()
                            let decoder = JSONDecoder()
                            self.homeNews = try decoder.decode([newsCard].self, from: json)

                            bookmarkHelper.updateGlobalBookmarkStatus(self.homeNews)
                            
                            // reload table after request has been fulfilled
                            self.tableView.reloadData()
                            
                            // fetch all images right after the search request and store them in a array
                            // this helps to:
                            // 1. prevent displaying wrong image on scroll caused by scrolling changes indexPath
                            // 2. improve app running speed b/c repeating image fetch requests due to indexPath change are avoided
                            for i in 0..<self.homeNews.count {
                                if let image = self.homeNews[i].image {
                                    if image == "" {
                                        self.newsImages.append(UIImage(named: "default-guardian")!)
                                    } else {
                                        if let imageUrl = URL(string: image) {
                                            let imageData = NSData(contentsOf: imageUrl)
                                            self.newsImages.append(UIImage(data: imageData! as Data)!)
                                        }
                                    }
                                } else {
                                    self.newsImages.append(UIImage(named: "default-guardian")!)
                                }
                            }
                            self.refreshControl.endRefreshing()
                            self.tableView.scrollToTop()
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
    

    
    // MARK: table view stubs
    // cell 0 is weather, rest 10 are news
    func numberOfSections(in tableView: UITableView) -> Int {
        return 11
    }

    // 1 section exactly 1 row
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    // section spacing is 5
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 5
    }

    // set section spacing bg to be clear, otherwise it's gray too
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }

    // now create a cell for each row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // if cell 0, use weather cell
        if indexPath.section == 0 {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "wCell", for: indexPath) as! weatherCell
            // remove selection style
            cell.selectionStyle = .none
            return cell
        }
        // otherwise, use news cell
        else {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! newsCardCell
            
            // set card colors
            cell.layer.borderColor = UIColor.lightGray.cgColor
            cell.layer.borderWidth = 1
            cell.layer.cornerRadius = 7
            
            cell.tag = indexPath.section

            cell.delegate = self
            // set card info
            if homeNews.count != 0 {
                let news = self.homeNews[cell.tag - 1]
                

                cell.id = news.articleID
                let currBookmark = globalBookmarks[cell.tag - 1]
                if (currBookmark.notMarked == false) {
                    cell.c_button.setImage(UIImage(systemName: "bookmark.fill"), for: .normal)
                }
                
                cell.c_image?.image = newsImages[cell.tag - 1]

                cell.c_title?.text = news.title
                cell.c_section?.text = "| " + news.section
                
                // parse time .. ago
                // get curr datetime
                let dateNow = Date()
                // get article datatime
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withInternetDateTime]
                // wrap b/c dateformatter return is optional
                if let dateTimeOfArticle = dateFormatter.date(from: news.time) {
                    // calculate diff btwn curr date and article publish date in seconds, wrap again b/c return value is optional
                    if let diffInSeconds = Calendar.current.dateComponents([.second], from: dateTimeOfArticle, to: dateNow).second {
                        // update display according to date difference
                        let diffInSecondsDouble: Double = Double(diffInSeconds)
                        if diffInSecondsDouble < 60 {
                            cell.c_time?.text = "\(Int(diffInSecondsDouble))s ago"
                        }
                        else if diffInSecondsDouble < 3600 {
                            cell.c_time?.text = "\(Int(diffInSecondsDouble/60))m ago"
                        }
                        else {
                            cell.c_time?.text = "\(Int(diffInSecondsDouble/3600))h ago"
                        }
                    }
                    
                }
                // remove selection style
                cell.selectionStyle = .none
                return cell
            }
            // if data not ready, simply return and wait for data to reload
            else {
                return cell
            }
        }
    }
    
    // set different cell height for weather and news cards
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 128.0
        } else {
            return 140.0
        }
    }

    // MARK: table view context menu
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        // we need the indexpath as identitifier to retrieve articleID for sharing and bookmark
        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: nil) {_ in
            // create twitter acction
            let share = UIAction(title: "Share with Twitter", image: UIImage(named: "twitter")) { action in
                // share via twitter
                let articleID = self.homeNews[indexPath.section-1].articleID
                let shareUrl = "https://www.theguardian.com/"+articleID
                let shareText = "Check out this Article! " + shareUrl + "\n#CSCI_571_NewsApp"

                let shareString = "https://twitter.com/intent/tweet?text=\(shareText)"
    
                let escapedShareString = shareString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
    
                guard let url = URL(string: escapedShareString) else {return;}
    
                UIApplication.shared.open(url, options: [:])
            }
            
            // create bookmark action
            let bookmark = UIAction(title: "Bookmark", image: UIImage(systemName: "bookmark")) { action in
                // bookmark functionality
                globalBookmarks[indexPath.section - 1].notMarked = !globalBookmarks[indexPath.section - 1].notMarked
                let tappedCell = tableView.cellForRow(at: indexPath) as! newsCardCell
                let image = globalBookmarks[indexPath.section - 1].notMarked ? UIImage(systemName: "bookmark") : UIImage(systemName: "bookmark.fill")
                
                // set image
                tappedCell.c_button.setImage(image, for: .normal)
                
                // set/remove bookmark
                !globalBookmarks[indexPath.section - 1].notMarked ? bookmarkHelper.addBookmark(globalBookmarks[indexPath.section - 1].cardInfo) : bookmarkHelper.removeBookmark(globalBookmarks[indexPath.section - 1].cardInfo)
                
                // make corresponding toast
                let toastMessage = !globalBookmarks[indexPath.section - 1].notMarked ? "Article Bookmarked. Check out the Bookmarks tab to view" : "Article Removed from Bookmarks"
                self.view.makeToast(toastMessage, duration: 1.0)
            }

            // create menu
            return UIMenu(title: "Menu", children: [share, bookmark])
        }
    }

    // MARK: detailed article
    var articleIdToPass: String!
    var articleCardInfoToPass: newsCard!
    // on table cell tap, if it is not the first weather cell, open detailed article page
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section != 0 {
            let currCellInd = indexPath.section - 1
            articleIdToPass = homeNews[currCellInd].articleID
            articleCardInfoToPass = homeNews[currCellInd]
            SwiftSpinner.show("Loading Detailed Article..")
            performSegue(withIdentifier: "articleSegue", sender: self)
        }
    }

    
    // prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "articleSegue" {
            // set back button text to empty
            let backItem = UIBarButtonItem()
            backItem.title = ""
            navigationItem.backBarButtonItem = backItem
            // pass the value of articleID to detailed article view for fetching full article
            let detailedArticleView = segue.destination as! detailedArticleVC
            detailedArticleView.articleID = articleIdToPass
            detailedArticleView.articleCardInfo = articleCardInfoToPass
        }
    }
    
}

// this extension scrollToTop is used for scrolling to top when app starts to run
extension UITableView {
    func hasRowAtIndexPath(_ indexPath: IndexPath) -> Bool {
        return indexPath.section < numberOfSections && indexPath.row < numberOfRows(inSection: indexPath.section)
    }

    func scrollToTop(_ animated: Bool = false) {
        let indexPath = IndexPath(row: 0, section: 0)
        if hasRowAtIndexPath(indexPath) {
            scrollToRow(at: indexPath, at: .top, animated: animated)
        }
    }
}

// extend uiimage with resize to width 500. used in all image requests except home b/c Guardian sometimes return very high res images
// Home news are fine since images used are thumbnails
extension UIImage {
    func resizeShrink() -> UIImage? {
        let imgSize = CGSize(width: 500, height: CGFloat(ceil(500 / size.width * size.height)))
        UIGraphicsBeginImageContextWithOptions(imgSize, false, scale)
        draw(in: CGRect(origin: .zero, size: imgSize))
        return UIGraphicsGetImageFromCurrentImageContext()
        
    }
}
