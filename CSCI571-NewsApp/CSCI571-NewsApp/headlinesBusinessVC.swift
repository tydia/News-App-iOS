//
//  headlinesBusinessVC.swift
//  CSCI571-NewsApp
//
//  Created by Tong Wang on 5/4/20.
//  Copyright © 2020 Tong Wang. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import SwiftSpinner
import Alamofire

class headlinesBusinessVC: UIViewController, IndicatorInfoProvider, UITableViewDelegate,  UITableViewDataSource, tableCellDelegate{
    
    @IBOutlet weak var tableView: UITableView!
    
    func didTapBookmark(_ message:String) {
        self.view.makeToast(message, duration: 1.0)
    }
    
    let spinnerMessage = "Loading BUSINESS Headlines.."
    let indicatorInfo = "BUSINESS"
    var allNews = [newsCard]()
    var newsImages = [UIImage]()
    let homeBackendUrl = "http://myiosnewsappbackend.us-east-1.elasticbeanstalk.com/business"
    
    let refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        SwiftSpinner.show(spinnerMessage)
        super.viewDidLoad()
        setupTableView()
        fetchNews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        bookmarkHelper.updateGlobalBookmarkStatus(self.allNews)
        tableView.reloadData()
    }
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: indicatorInfo)
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
                            self.allNews.removeAll()
                            self.refreshControl.beginRefreshing()
                            let decoder = JSONDecoder()
                            self.allNews = try decoder.decode([newsCard].self, from: json)

                            
                            bookmarkHelper.updateGlobalBookmarkStatus(self.allNews)
                            
                            // reload table after request has been fulfilled
                            self.tableView.reloadData()
                            
                            // fetch all images right after the search request and store them in a array
                            // this helps to:
                            // 1. prevent displaying wrong image on scroll caused by scrolling changes indexPath
                            // 2. improve app running speed b/c repeating image fetch requests due to indexPath change are avoided
                            for i in 0..<self.allNews.count {
                                if let image = self.allNews[i].image {
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
                            
                            SwiftSpinner.hide()
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
        return 10
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


            let cell = self.tableView.dequeueReusableCell(withIdentifier: "worldCell", for: indexPath) as! newsCardCell
            
            // set card colors
            cell.layer.borderColor = UIColor.lightGray.cgColor
            cell.layer.borderWidth = 1
            cell.layer.cornerRadius = 7
        
            // attatch section as tag for get image from image array
            cell.tag = indexPath.section
        
            // set card info
            if allNews.count != 0 {
                let news = self.allNews[indexPath.section]
                
                cell.id = news.articleID
                let currBookmark = globalBookmarks[cell.tag]
                if (currBookmark.notMarked == false) {
                    cell.c_button.setImage(UIImage(systemName: "bookmark.fill"), for: .normal)
                }
                
                cell.delegate = self
                cell.c_image?.image = self.newsImages[cell.tag].resizeShrink()
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
    

    // MARK: table view context menu
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        // we need the indexpath as identitifier to retrieve articleID for sharing and bookmark
        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: nil) {_ in
            // create twitter acction
            let share = UIAction(title: "Share with Twitter", image: UIImage(named: "twitter")) { action in
                // share via twitter
                let articleID = self.allNews[indexPath.section].articleID
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
                globalBookmarks[indexPath.section].notMarked = !globalBookmarks[indexPath.section].notMarked
                let tappedCell = tableView.cellForRow(at: indexPath) as! newsCardCell
                let image = globalBookmarks[indexPath.section].notMarked ? UIImage(systemName: "bookmark") : UIImage(systemName: "bookmark.fill")
                
                // set image
                tappedCell.c_button.setImage(image, for: .normal)
                
                // set/remove bookmark
                !globalBookmarks[indexPath.section].notMarked ? bookmarkHelper.addBookmark(globalBookmarks[indexPath.section].cardInfo) : bookmarkHelper.removeBookmark(globalBookmarks[indexPath.section].cardInfo)
                
                // make corresponding toast
                let toastMessage = !globalBookmarks[indexPath.section].notMarked ? "Article Bookmarked. Check out the Bookmarks tab to view" : "Article Removed from Bookmarks"
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
        let currCellInd = indexPath.section
        articleIdToPass = allNews[currCellInd].articleID
        articleCardInfoToPass = allNews[currCellInd]
        SwiftSpinner.show("Loading Detailed Article..")
        performSegue(withIdentifier: "articleSegue", sender: self)
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
