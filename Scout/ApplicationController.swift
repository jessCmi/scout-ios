//
//  ApplicationViewController.swift
//  Scout
//
//  Created by Charlon Palacay on 8/11/16.
//  Copyright © 2016 Charlon Palacay. All rights reserved.
//

import UIKit
import WebKit
import Turbolinks
import CoreLocation

class ApplicationController: UINavigationController,  CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    
    var URL: NSURL {
        return NSURL(string: "\(host)\(campus)/")!
    }
            
    private let webViewProcessPool = WKProcessPool()
    
    private var application: UIApplication {
        return UIApplication.sharedApplication()
    }
    
    private lazy var webViewConfiguration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        
        // name of js script handler that this controller with be communicating with
        configuration.userContentController.addScriptMessageHandler(self, name: "scoutBridge")
        
        configuration.processPool = self.webViewProcessPool
        return configuration
    }()
    
    private lazy var session: Session = {
        let session = Session(webViewConfiguration: self.webViewConfiguration)
        session.delegate = self
        return session
    }()
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presentVisitableForSession(session, URL: URL)
    }
 
    override func viewDidAppear(animated:Bool) {
        super.viewDidAppear(animated)
        
        let sessionURL = session.webView.URL?.absoluteString
        
        // print the 2 urls the app has for comparison
        print("requested url \(URL)")
        print("session url \(sessionURL!)")
        
        // check to see if the campus has changed from what was previously set in session
        if sessionURL!.lowercaseString.rangeOfString(campus) == nil {
            //print("campus changed")
            presentVisitableForSession(session, URL: URL, action: .Replace)
        }
        
    }
    
    
    // generic visit controller
    func presentVisitableForSession(session: Session, URL: NSURL, action: Action = .Advance) {
        
        let visitable = VisitableViewController(URL: URL)
                
        // handle actions
        if action == .Advance {
            pushViewController(visitable, animated: true)
        } else if action == .Replace {
            popViewControllerAnimated(true)
            //pushViewController(visitable, animated: false)
            setViewControllers([visitable], animated: false)
        }
        
        session.visit(visitable)
        
    }
    
    // show filter
    func presentFilter() {
        let URL = NSURL(string: "\(host)\(campus)/\(app_type)/filter/?\(params)")!
        //print(URL)
        presentVisitableForSession(session, URL: URL)
    }
    
    // execute javascript
    func submitFilter(){
        
        // set a new visitable that includes
        let URL = NSURL(string: "\(host)\(campus)/\(app_type)/?\(params)")!
        let sessionURL = session.webView.URL?.absoluteString
        
        // force reload (replace) of viewcontroller if params have changed or cleared
        if sessionURL!.lowercaseString.rangeOfString(params) == nil {
            //print(sessionURL!)
            //print(params)
            //print("params changed")
            presentVisitableForSession(session, URL: URL, action: .Replace)
        } else {
            //print(sessionURL!)
            //print(params)
            //print("params not changed")
            popViewControllerAnimated(true);
        }
        
    }
    
    func clearFilter(){
        // evaluate js by submitting click event
        session.webView.evaluateJavaScript("document.getElementById('filter_clear').click()", completionHandler: nil)
    }
    
    // custom controller for campus selection
    func chooseCampus() {
        
        // 1
        let optionMenu = UIAlertController(title: nil, message: "Choose Campus", preferredStyle: .ActionSheet)
        
        // 2
        let smithAction = UIAlertAction(title: "Smith", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            //print("Seattle was selected")
            campus = "smith"
            self.presentVisitableForSession(self.session, URL: self.URL, action: .Replace)
        })
//        let seattleAction = UIAlertAction(title: "Seattle", style: .Default, handler: {
//            (alert: UIAlertAction!) -> Void in
//            //print("Seattle was selected")
//            campus = "seattle"
//            self.presentVisitableForSession(self.session, URL: self.URL, action: .Replace)
//        })
//        let bothellAction = UIAlertAction(title: "Bothell", style: .Default, handler: {
//            (alert: UIAlertAction!) -> Void in
//            //print("Bothell was selected")
//            campus = "bothell"
//            print(self.URL)
//            self.presentVisitableForSession(self.session, URL: self.URL, action: .Replace)
//        })
//        let tacomaAction = UIAlertAction(title: "Tacoma", style: .Default, handler: {
//            (alert: UIAlertAction!) -> Void in
//            //print("Tacoma was selected")
//            campus = "tacoma"
//            self.presentVisitableForSession(self.session, URL: self.URL, action: .Replace)
//        })
        
        //
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            //print("Cancelled")
        })
        
        
        // 4
        optionMenu.addAction(smithAction)
//        optionMenu.addAction(seattleAction)
//        optionMenu.addAction(bothellAction)
//        optionMenu.addAction(tacomaAction)
        
        optionMenu.addAction(cancelAction)
        
        // 5
        self.presentViewController(optionMenu, animated: true, completion: nil)
        
    }
    
    func openSettings() {
        // no longer supported in ios10.. sucks!
        // UIApplication.sharedApplication().openURL(NSURL(string:"prefs:root=Scout")!)
    }
    
    
    func setUserLocation() {
        
        // ask authorization only when in use by user
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            
            //print("location enabled.. send user lat/lng")

            locationManager.delegate = self
            locationManager.distanceFilter = 30 // meters
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            
        }
        else {
            print("location disabled.. will use default locations instead")
        }
        
    }
    
    // locationManager delegate functions
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        
        //print("position to send = \(locValue.latitude) \(locValue.longitude)")
        
        // send the lat/lng to the geolocation function on web
        // session.webView.evaluateJavaScript("$.event.trigger(Geolocation.location_updating)", completionHandler: nil)
        session.webView.evaluateJavaScript("Geolocation.set_is_using_location(true)", completionHandler: nil)
        session.webView.evaluateJavaScript("Geolocation.send_client_location(\(locValue.latitude),\(locValue.longitude))", completionHandler: nil)
        
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        //print("Error while updating location: " + error.localizedDescription)
        session.webView.evaluateJavaScript("Geolocation.set_is_using_location(false)", completionHandler: nil)
    }
    
}

extension ApplicationController: SessionDelegate {
    func session(session: Session, didProposeVisitToURL URL: NSURL, withAction action: Action) {
        presentVisitableForSession(session, URL: URL, action: action)
    }
    
    func session(session: Session, didFailRequestForVisitable visitable: Visitable, withError error: NSError) {
        let alert = UIAlertController(title: "Error Requesting Data", message: "This data is temporarily unavailable. Please try again later.", preferredStyle: .Alert)
        //alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action: UIAlertAction!) in
            self.popToRootViewControllerAnimated(true)
        }))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func sessionDidStartRequest(session: Session) {
        application.networkActivityIndicatorVisible = true
        
       
    }
    
    func sessionDidFinishRequest(session: Session) {
        application.networkActivityIndicatorVisible = false
        
        // send user's location once webview has finished loading
        setUserLocation()
    }
    
}

extension ApplicationController: WKScriptMessageHandler {
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        
        // set the params from the js bridge message
        if let message = message.body as? String {
            //print(message)
            params = message
        }
        
    }
    
}
