//
//  BookmarksViewController.swift
//  CSCI571-NewsApp
//
//  Created by Tong Wang on 4/21/20.
//  Copyright © 2020 Tong Wang. All rights reserved.
//

import UIKit
import SwiftSpinner

// this protocol is used for telling parent view from a cell that the bookmark button inside that cell istapped
protocol bookmarksCellDelegate {
    func didTapReload()
}

// custom news card cell
class bookmarksCell: UICollectionViewCell {

    @IBOutlet weak var b_image: UIImageView!
    @IBOutlet weak var b_title: UILabel!
    @IBOutlet weak var b_time: UILabel!
    @IBOutlet weak var b_section: UILabel!
    @IBOutlet var b_button: UIButton!
    // news to be removed
    var newsToRemove:newsCard? = nil
    // declare delegate
    var delegate: bookmarksCellDelegate?
    
    @IBAction func bookmarking(_ sender: UIButton) {
        if let news = newsToRemove {
            // remove bookmark, set button image, and make a toast
            bookmarkHelper.removeBookmark(news)
            b_button.setImage(UIImage(systemName: "bookmark"), for: .normal)
            self.superview?.superview?.superview?.makeToast("Article Removed from Bookmarks", duration: 1.0)
            // call protocol function that is implemented in parent view
            delegate?.didTapReload()
        }
    }

}

class BookmarksViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, bookmarksCellDelegate {
    @IBOutlet weak var bookmarksCollection: UICollectionView!
    
    var bookmarkedNews:[newsCard] = []
//    var newsImages = [UIImage]()
    
    let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 25))
    
    func didTapReload() {
        self.reloadBookmarksData()
    }
    
    override func viewDidLoad() {
        reloadBookmarksData()
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        bookmarksCollection.delegate = self
        bookmarksCollection.dataSource = self
        
        initNoBookmarksLabel()
                
        let cellWidth = (view.frame.size.width - 40) / 2 // 187.0 in iphone 11 pro max
        let layout = bookmarksCollection.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: cellWidth, height: 258)
        
    }
    
    
    func initNoBookmarksLabel() {
        label.center = CGPoint(x: view.frame.size.width/2, y: view.frame.size.height/2)
        label.font = label.font.withSize(20)
        label.textAlignment = .center
        label.text = "No bookmarks added."
    }
    
    func reloadBookmarksData() {
        navigationController?.navigationBar.prefersLargeTitles = true
        if let localBookmarks = bookmarkHelper.getBookmarks() {
            bookmarkedNews = localBookmarks
            if bookmarkedNews.count == 0 {
                bookmarksCollection.isHidden = true
                self.view.addSubview(label)
            } else {
                label.removeFromSuperview()
                bookmarksCollection.isHidden = false
                self.bookmarksCollection.reloadData()
            }
        } else {
            bookmarksCollection.isHidden = false
            self.view.addSubview(label)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadBookmarksData()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.bookmarkedNews.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "bookmarkCell", for: indexPath) as! bookmarksCell
        // set card styles
        cell.layer.borderColor = UIColor.gray.cgColor
        cell.layer.borderWidth = 1
        cell.layer.cornerRadius = 7

        if bookmarkedNews.count != 0 {
            let currNews = bookmarkedNews[indexPath.row]
            // pass delegate
            cell.delegate = self
            
            cell.newsToRemove = currNews
            
            // set card info
            cell.b_button.setImage(UIImage(systemName: "bookmark.fill"), for: .normal)
            cell.b_title?.text = currNews.title
            cell.b_section?.text = currNews.section
            cell.b_image?.image = bookmarkHelper.getImage(forKey: currNews.articleID)
            // date
            let dateFormatter = ISO8601DateFormatter()
            if let date = dateFormatter.date(from: currNews.time) {
                cell.b_time.text = date.ddMMMyyyy
            }
        }
        
        return cell
    }
    

    // MARK: detailed article
    var articleIdToPass: String!
    var articleCardInfoToPass: newsCard!
    // on table cell tap, if it is not the first weather cell, open detailed article page
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let currCellInd = indexPath.row
        articleIdToPass = bookmarkedNews[currCellInd].articleID
        articleCardInfoToPass = bookmarkedNews[currCellInd]
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
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { suggestedActions in
            // create twitter acction
            let share = UIAction(title: "Share with Twitter", image: UIImage(named: "twitter")) { action in
                // share via twitter
                let articleID = self.bookmarkedNews[indexPath.section].articleID
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
                let tappedCell = collectionView.cellForItem(at: indexPath) as! bookmarksCell
                
                // set image
                tappedCell.b_button.setImage(UIImage(systemName: "bookmark"), for: .normal)
                
                // set/remove bookmark
                bookmarkHelper.removeBookmark(self.bookmarkedNews[indexPath.row])
                
                // make corresponding toast
                self.view.makeToast("Article Removed from Bookmarks", duration: 1.0)
                
                self.reloadBookmarksData()
            }

            // create menu
            return UIMenu(title: "Menu", children: [share, bookmark])
        })
    }
}
