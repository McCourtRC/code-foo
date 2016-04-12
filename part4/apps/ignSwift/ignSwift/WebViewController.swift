//
//  WebViewController.swift
//  ignSwift
//
//  Created by Corey McCourt on 4/11/16.
//  Copyright © 2016 Corey McCourt. All rights reserved.
//

import UIKit

class WebViewController: UIViewController {
    
    // MARK: - Variables
    @IBOutlet weak var webView: UIWebView!
    var url = String()

    // MARK: - Functions
    @IBAction func backButton(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.webView.loadRequest(NSURLRequest(URL: NSURL(string: self.url)!))
    }

}
