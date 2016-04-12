//
//  ViewController.swift
//  ignSwift
//
//  Created by Corey McCourt on 4/10/16.
//  Copyright © 2016 Corey McCourt. All rights reserved.
//

import UIKit
import Alamofire    // for HTTP requests
import SwiftDate    // for time calculations


class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    //MARK: - Variables
    @IBOutlet weak var tableView: UITableView!
    var refreshControl = UIRefreshControl()

    // Number of results per API call
    let resPerQuery = 3
    
    // Holds the table data
    var tableData = [ignData]()
    
    // Url of selected table row to pass to next view controller
    var selectedUrl = String()
    
    // Struct for relevant info from IGN API
    struct ignData {
        var date: NSDate
        var title: String
        var type: String
        var imageUrl: String
        var url: String
        
    }
    
    //MARK: - Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // Refresh Indicator Settings
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.tintColor = UIColor.redColor()
        self.refreshControl.addTarget(self, action: #selector(self.refresh), forControlEvents: .ValueChanged)
        self.tableView.addSubview(self.refreshControl)
        
        loadData()
    }
    
    func refresh() {
        self.tableData.removeAll()
        loadData()
    }
    
    func loadData(more more: Bool = false) {
        /*
         Load data from IGN API using two separate queries for articles and videos.
         Use dispatch groups to keep track of when all HTTP calls have completed.
         Set 'more' to true in order to append information to tableData using startIndex for pagination
         
         *** Sort available to order results by default, but cells get rearranged on scroll down
         *** Issue could be solved by keeping track of whether an 'article' or 'video' query reveals newer results
         *** and then adding those results to tableData and querying more results for comparison
        */
        
        // Set start index for pagination if loading more
        var startIndex = 0
        if more {
            startIndex = tableData.count - 1
        }
        
        // Create dispatch group for control with async HTTP calls
        let loadGroup = dispatch_group_create()
        
        // Get articles
        dispatch_group_enter(loadGroup)
        let articleUrl = ignAPIUrl(withType: "articles", startIndex: startIndex, count: resPerQuery)
        loadArticles(withUrl: articleUrl, dispatchGroup: loadGroup)
        
        // Get videos
        dispatch_group_enter(loadGroup)
        let videoUrl = ignAPIUrl(withType: "videos", startIndex: startIndex, count: resPerQuery)
        loadVideos(withUrl: videoUrl, dispatchGroup: loadGroup)
        
        
        // Handle group completion
        dispatch_group_notify(loadGroup, dispatch_get_main_queue()) {
            /* Sort results *** see description above for details
            
             
            self.tableData.sortInPlace({
                $0.date.compare($1.date) == NSComparisonResult.OrderedDescending
            })
            */
            
            // tell refresh control it can stop showing up now
            if self.refreshControl.refreshing
            {
                self.refreshControl.endRefreshing()
            }
            
            self.tableView.reloadData()
        }
    }
    
    func loadArticles(withUrl url: String, dispatchGroup: dispatch_group_t) {
        // Insert new data using Alamofire get request
        Alamofire.request(.GET, url)
            .responseJSON { response in
                if let JSON = response.result.value {
                    let dataArray = JSON["data"]
                    
                    // Iterate through results array
                    for item in dataArray as! [AnyObject] {
                        let metadata = item["metadata"]
                        
                        let dateString = metadata!!["publishDate"] as! String
                        let date = self.stringToNSDate(dateString)
                        
                        let t = metadata!!["headline"] as! String
                        let title = t.uppercaseString
                        
                        let type = "article"
                        
                        let imageUrl = item["thumbnail"] as! String
                        
                        let slug = metadata!!["slug"] as! String
                        let url = self.articleURL(fromDateString: dateString, slug: slug)
                        
                        let data = ignData(date: date, title: title, type: type, imageUrl: imageUrl, url: url)
                        
                        self.tableData.append(data)
                    }
                }
                
                // Notify function finished
                dispatch_group_leave(dispatchGroup)
        }
    }
    
    func loadVideos(withUrl url: String, dispatchGroup: dispatch_group_t) {
        // Insert new data using Alamofire get request
        Alamofire.request(.GET, url)
            .responseJSON { response in
                if let JSON = response.result.value {
                    let dataArray = JSON["data"]
                    
                    // Iterate through results array
                    for item in dataArray as! [AnyObject] {
                        let metadata = item["metadata"]
                        
                        let dateString = metadata!!["publishDate"] as! String
                        let date = self.stringToNSDate(dateString)
                        
                        let t = metadata!!["name"] as! String
                        let title = t.uppercaseString
                        
                        let type = "video"
                        
                        let imageUrl = item["thumbnail"] as! String
                        
                        let url = metadata!!["url"] as! String
                        
                        let data = ignData(date: date, title: title, type: type, imageUrl: imageUrl, url: url)
                        
                        self.tableData.append(data)
                    }
                }
                
                // Notify function finished
                dispatch_group_leave(dispatchGroup)
        }
    }
    
    // MARK: - Table View
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        /*
         Place every item in its own section in order to get section footers for each item.
         This is for simple format spacing between each item.
         */
        return self.tableData.count
    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("customCell", forIndexPath: indexPath);
        let data = self.tableData[indexPath.section]
        
        if let timeLabel = cell.viewWithTag(100) as? UILabel {
            let time = timeAgo(fromNSDate: data.date)
            timeLabel.text = time.uppercaseString
        }
        
        if let titleLabel = cell.viewWithTag(200) as? UILabel {
            titleLabel.text = data.title
        }
        
        if let image = cell.viewWithTag(300) as? UIImageView {
            let urlContents = NSURL(string: data.imageUrl)
            let data = NSData(contentsOfURL: urlContents!)
            image.image = UIImage(data:data!)
        }
        
        if let playbutton = cell.viewWithTag(400) as? UIImageView {
            playbutton.hidden = data.type != "video" ? true : false
        }
        
        // Load more data if at the end of the table
        if indexPath.section == self.tableData.count - 1 {
            loadData(more: true)
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedUrl = tableData[indexPath.section].url
        self.performSegueWithIdentifier("WebPage", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "WebPage"{
            let vc = segue.destinationViewController as! WebViewController
            vc.url = selectedUrl
        }
    }
    
    // MARK: - Utilities
    func timeAgo(fromNSDate date: NSDate) -> String {
        let currTime = NSDate()
        
        let rawTime = date.toNaturalString(currTime, inRegion: nil, style: FormatterStyle(style: .Short, units: nil, max: 1))
        let time = rawTime! + " ago"
        
        return time
    }
    
    func stringToNSDate(dateString: String) -> NSDate {
        let df = NSDateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let date = df.dateFromString(dateString)
        return date!
    }
    
    func ignAPIUrl(withType type: String, startIndex: Int = 0,  count: Int) -> String{
        let baseUrl = "http://ign-apis.herokuapp.com/"
        let urlType = baseUrl + type + "?"
        let urlStart = urlType + "startIndex=" + String(startIndex) + "&"
        let urlCount = urlStart + "count=" + String(count)
        
        return urlCount
    }
    
    func articleURL(fromDateString dateString: String, slug: String) -> String{
        let baseURL = "http://www.ign.com/articles/"
        let urlDate = baseURL + dateStringToUrlDate(dateString)
        let url = urlDate + slug
        return url
    }
    
    func dateStringToUrlDate(datestring: String) -> String {
        let sepDate = datestring.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "-T"))
        let year = sepDate[0]
        let month = sepDate[1]
        let day = sepDate[2]
        
        return year + "/" + month + "/" + day + "/"
    }
}

