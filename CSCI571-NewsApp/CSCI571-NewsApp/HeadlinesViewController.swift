//
//  HeadlinesViewController.swift
//  CSCI571-NewsApp
//
//  Created by Tong Wang on 4/20/20.
//  Copyright © 2020 Tong Wang. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class HeadlinesViewController: ButtonBarPagerTabStripViewController {
    
    override func viewDidLoad() {
        loadStyle()
        super.viewDidLoad()
        setupNavbar()
        
    }
    
    override public func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let worldSection = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "worldNewsTable")
        let businessSection = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "businessNewsTable")
        let politicsSection = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "politicsNewsTable")
        let sportSection = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "sportNewsTable")
        let technologySection = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "technologyNewsTable")
        let scienceSection = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "scienceNewsTable")
        return [worldSection, businessSection, politicsSection, sportSection, technologySection, scienceSection]
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
    
    func loadStyle() {
        self.settings.style.buttonBarItemFont = .boldSystemFont(ofSize: 17)
        self.settings.style.buttonBarItemTitleColor = .init(red: 50/255, green: 130/255, blue: 223/255, alpha: 1)
        self.settings.style.selectedBarBackgroundColor = .init(red: 85/255, green: 150/255, blue: 245/255, alpha: 1)
        self.settings.style.buttonBarItemBackgroundColor = .clear

        settings.style.buttonBarLeftContentInset = 10
        settings.style.buttonBarRightContentInset = 10
        settings.style.selectedBarHeight = 3

        changeCurrentIndexProgressive = { (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            guard changeCurrentIndex == true else { return }
            oldCell?.label.textColor = UIColor.gray
            newCell?.label.textColor = .init(red: 85/255, green: 150/255, blue: 245/255, alpha: 1)
        }
    }


}

