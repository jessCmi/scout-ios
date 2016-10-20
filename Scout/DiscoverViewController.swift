//
//  DiscoverViewController.swift
//  Scout
//
//  Created by Charlon Palacay on 7/14/16.
//  Copyright © 2016 Charlon Palacay. All rights reserved.
//

import UIKit
import WebKit
import Turbolinks

class DiscoverViewController: UINavigationController {
    
    var URL: NSURL {
        return NSURL(string: "\(host)/\(campus)/")!
    }
    
    private let webViewProcessPool = WKProcessPool()
    
    private var application: UIApplication {
        return UIApplication.sharedApplication()
    }
    
    private lazy var webViewConfiguration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = self.webViewProcessPool
        return configuration
    }()
    
    private lazy var session: Session = {
        let session = Session(webViewConfiguration: self.webViewConfiguration)
        session.delegate = self
        return session
    }()
    
    override func viewDidLoad() {
        
        print(URL);
        
        super.viewDidLoad()
        presentVisitableForSession(session, URL: URL)
    }
    
    // visit controller for discover
    
    func presentVisitableForSession(session: Session, URL: NSURL, action: Action = .Advance) {
        
        let visitable = VisitableViewController(URL: URL)
        
        // only load the right button at the root discover URL
        if URL.path == "/h/\(campus)" {
            print("on discover home");
            
            // YESSSSS! Adds a right button to the visitable controller
            visitable.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Campus", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(DiscoverViewController.chooseCampus))
        }
        
        if action == .Advance {
            pushViewController(visitable, animated: true)
        } else if action == .Replace {
            
            //popViewControllerAnimated(false)
            //pushViewController(visitable, animated: false)
            
            // replaced old action with the following that seems to work better
            popViewControllerAnimated(true)
            setViewControllers([visitable], animated: false)
        }
        
        session.visit(visitable)
        
    }
    
    // custom controller for campus selection
    func chooseCampus() {
        
        // 1
        let optionMenu = UIAlertController(title: nil, message: "Choose Campus", preferredStyle: .ActionSheet)
        
        // 2
        let seattleAction = UIAlertAction(title: "Seattle", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Seattle was selected")
        })
        let bothellAction = UIAlertAction(title: "Bothell", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Bothell was selected")
            
            // TODO: replace the campus setting at the appDelegate level. Not working yet!
            // For now, this campus is only local to the the discover controller.
            let campus = "bothell"
            let URL = NSURL(string: "\(host)/\(campus)")!
            
            // present the visitable URL with specific replace action
            self.presentVisitableForSession(self.session, URL: URL, action: .Replace)
            
            // TODO: when the campus is set at the appDelegate level, should just be able to 
            // call self.URL instead since campus will have been reset globally.
            // self.presentVisitableForSession(self.session, URL: self.URL, action: .Replace)
            
        })
        let tacomaAction = UIAlertAction(title: "Tacoma", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Tacoma was selected")
        })
        
        //
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Cancelled")
        })
        
        
        // 4
        optionMenu.addAction(seattleAction)
        optionMenu.addAction(bothellAction)
        optionMenu.addAction(tacomaAction)
        
        optionMenu.addAction(cancelAction)
        
        // 5
        self.presentViewController(optionMenu, animated: true, completion: nil)
        
        
    }
    
}

extension DiscoverViewController: SessionDelegate {
    func session(session: Session, didProposeVisitToURL URL: NSURL, withAction action: Action) {
        
        // EXAMPPLE: intercept link clicks and do something custom
        
        if URL.path == "/h/seattle/food/filterxxx" {
            // define some custom function
            
        } else {
            presentVisitableForSession(session, URL: URL, action: action)
        }
        
    }
    
    func session(session: Session, didFailRequestForVisitable visitable: Visitable, withError error: NSError) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func sessionDidStartRequest(session: Session) {
        application.networkActivityIndicatorVisible = true
    }
    
    func sessionDidFinishRequest(session: Session) {
        application.networkActivityIndicatorVisible = false
    }
}

