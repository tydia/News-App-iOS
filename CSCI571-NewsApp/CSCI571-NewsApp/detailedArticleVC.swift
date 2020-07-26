//
//  detailedArticleVC.swift
//  CSCI571-NewsApp
//
//  Created by Tong Wang on 5/2/20.
//  Copyright © 2020 Tong Wang. All rights reserved.
//

import UIKit
import SwiftSpinner
import Alamofire
import SwiftyJSON
import Toast_Swift

class detailedArticleVC: UIViewController {
    // stores the article id to fetch
    var articleID: String = ""
    var articleCardInfo: newsCard? = nil
    
    @IBOutlet weak var article_img: UIImageView!
    @IBOutlet weak var article_title: UILabel!
    @IBOutlet weak var article_section: UILabel!
    @IBOutlet weak var article_date: UILabel!
    @IBOutlet weak var article_desc: UILabel!
    @IBOutlet weak var article_button: UIButton!
    
    @IBOutlet var bookmarkBarButton: UIBarButtonItem!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        
        if let cardInfo = articleCardInfo {
            if let currBookmarks = bookmarkHelper.getBookmarks() {
                let bookmarkFound = bookmarkHelper.searchBookmarks(currBookmarks, cardInfo)
                // if curr article id found in user defaults, set notMarked to false, meaning that the article was bookmarked
                if bookmarkFound {
                    notBookmarked = false
                }
                // otherwise this article was not bookmarked
                else {
                    notBookmarked = true
                }
                // toggle button image
                let image = notBookmarked ? UIImage(systemName: "bookmark") : UIImage(systemName: "bookmark.fill")
                bookmarkBarButton.image = image
            }
        }

        
        let fetchUrl: String = "http://myiosnewsappbackend.us-east-1.elasticbeanstalk.com/article/getArticle?id=" + articleID //"world/live/2020/may/07/coronavirus-us-live-donald-trump-shelves-cdc-reopening-guidelines-cuomo-latest-news-updates"
        fetchDetailedArticle(url: fetchUrl)
        
        // setup button interaction UI
        article_button.layer.cornerRadius = 5
        article_button.addTarget(self, action: #selector(unHold), for: .touchUpInside);
        article_button.addTarget(self, action: #selector(hold), for: .touchDown)
        article_button.addTarget(self, action: #selector(holdThenUnhold), for: .touchDragExit)
    }
    
    // for user-button interaction UI
    @objc func hold() {
        article_button.backgroundColor = .lightGray
    }
    @objc func unHold() {
        article_button.backgroundColor = .clear
    }
    @objc func holdThenUnhold(){
        article_button.backgroundColor = .clear
    }

    func fetchDetailedArticle(url:String) {
        Alamofire.request(url)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseJSON { response in
                switch response.result {
                case .success:
                    if let json = response.data {
                        do{
                            let data = try JSON(data: json)
                            // get info to update detailed article
                            let a_title_str = "\(data["title"])"
                            let a_section_str = "\(data["section"])"
                            
                            // update detailed article UI labels
                            self.navigationItem.title = a_title_str
                            self.article_title.text = a_title_str
                            self.article_section.text = a_section_str
                            // desc
//                            self.article_desc.attributedText = a_desc_str
//                            print(data["description"].description.count)
//                            print(String(data["description"].description.prefix(8000)).count)
                            self.article_desc.attributedText = String(data["description"].description.prefix(8000)).htmlToAttributedString
                            self.article_desc.font = UIFont(name: "System", size: 20)//self.article_desc.font.withSize(17)
                            self.article_desc.lineBreakMode = .byTruncatingTail
                            self.article_desc.sizeToFit()
                            self.article_desc.numberOfLines = 30
                            
                            
                            // img
                            if data["image"].description == "" {
                                SwiftSpinner.hide()
                                self.article_img.image = (UIImage(named: "default-guardian")!)
                            } else {
                                if let imageUrl = URL(string: data["image"].description) {
                                    SwiftSpinner.hide()
                                    let imageData = NSData(contentsOf: imageUrl)
                                    self.article_img.image = UIImage(data: imageData! as Data)!
                                }
                                SwiftSpinner.hide()
                            }
                            
                            // date
                            let dateFormatter = ISO8601DateFormatter()
                            if let date = dateFormatter.date(from: "\(data["date"])") {
                                self.article_date.text = date.ddMMMyyyy
                            }
                        }
                        catch{
                            print("Some errors occured when parsing weather response JSON")
                        }
                        
                    }
                case let .failure(error):
                    print(error)
                }
            }
    }
    
    // on view full article tap, open link in safari
    @IBAction func openInSafari(_ sender: UIButton) {
        if let url = URL(string: "https://www.theguardian.com/"+articleID) {
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    @IBAction func twitterShare(_ sender: UIBarButtonItem) {
        let shareUrl = "https://www.theguardian.com/"+articleID
        let shareText = "Check out this Article! " + shareUrl + "\n#CSCI_571_NewsApp"
        
        
        let shareString = "https://twitter.com/intent/tweet?text=\(shareText)"
        
        let escapedShareString = shareString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        guard let url = URL(string: escapedShareString) else {return;}
        
        UIApplication.shared.open(url, options: [:])

    }
    var notBookmarked = true
    @IBAction func addBookmark(_ sender: Any) {
        notBookmarked = !notBookmarked
        if let cardInfo = self.articleCardInfo {
            !notBookmarked ? bookmarkHelper.addBookmark(cardInfo) : bookmarkHelper.removeBookmark(cardInfo)
        }
        
        // toggle button image
        let image = notBookmarked ? UIImage(systemName: "bookmark") : UIImage(systemName: "bookmark.fill")
        bookmarkBarButton.image = image
        
        
        // make toast
        let toastMessage = !notBookmarked ? "Article Bookmarked. Check out the Bookmarks tab to view" : "Article Removed from Bookmarks"
        self.view.makeToast(toastMessage, duration: 1.0)
        
    }
    
}

// extend string method to parse html as attributed string
// reference: https://stackoverflow.com/questions/37048759/swift-display-html-data-in-a-label-or-textview
extension String {
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return NSAttributedString() }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            return NSAttributedString()
        }
    }
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
}

// extend date with required date format
extension Date {
    var ddMMMyyyy: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: self)
    }
}
