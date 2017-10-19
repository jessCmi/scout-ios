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

class ApplicationController: UINavigationController {


    var URL: Foundation.URL {
        return Foundation.URL(string: "\(host)\(campus)/")!
    }

    fileprivate let webViewProcessPool = WKProcessPool()

    fileprivate var application: UIApplication {
        return UIApplication.shared
    }

    fileprivate lazy var webViewConfiguration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()

        // name of js script handler that this controller with be communicating with
        configuration.userContentController.add(self, name: "scoutBridge")

        configuration.processPool = self.webViewProcessPool
        return configuration
    }()

    fileprivate lazy var session: Session = {
        let session = Session(webViewConfiguration: self.webViewConfiguration)
        session.webView.allowsLinkPreview = false
        session.delegate = self
        return session
    }()

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        presentVisitableForSession(session, URL: URL)
    }

    // generic visit controller
    func presentVisitableForSession(_ session: Session, URL: Foundation.URL, action: Action = .Advance) {

        let visitable = VisitableViewController(url: URL)

        // handle actions
        if action == .Advance {
            pushViewController(visitable, animated: true)
        } else if action == .Replace {
            popViewController(animated: true)
            setViewControllers([visitable], animated: false)
        }

        session.visit(visitable)

    }

    // show filter
    @objc func presentFilter() {
        let URL = Foundation.URL(string: "\(host)\(campus)/\(app_type)/filter/?\(params)")!
        presentVisitableForSession(session, URL: URL)
    }

    // submit filter function when user clickes on the filter back button
    @objc func submitFilter(){

        // set a new visitable that includes
        let visitURL = Foundation.URL(string: "\(host)\(campus)/\(app_type)/?\(params)")!

        // get the previous URL and params from the session URL (presentFilter function)
        let sessionURL = session.webView.url?.absoluteString
        // remove the filter/ string from the URL
        let previousURL = sessionURL?.replacingOccurrences(of: "filter/", with: "")

        print(previousURL!)
        print(visitURL.absoluteString)

        // check to see if the new visit URL matches what the user previously visited
        if (visitURL.absoluteString == previousURL!) {
            // if URLs match... no need to reload, just pop
            print("params are same")
            popViewController(animated: true);
        } else {
            // if they are different, force a reload by using the Replace action
            print("params are different")
            presentVisitableForSession(session, URL: visitURL, action: .Replace)
        }

    }

    @objc func clearFilter(){
        // evaluate js by submitting click event
        session.webView.evaluateJavaScript("document.getElementById('filter_clear').click()", completionHandler: nil)
    }

    // custom controller for campus selection
    func chooseCampus() {

        // 1
        let optionMenu = UIAlertController(title: nil, message: "Choose Campus", preferredStyle: .actionSheet)

        // 2
        let smithAction = UIAlertAction(title: "Smith", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            campus = "smith"
            self.presentVisitableForSession(self.session, URL: self.URL, action: .Replace)
        })

        //
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
        })


        // 4
        optionMenu.addAction(smithAction)

        optionMenu.addAction(cancelAction)

        // 5
        self.present(optionMenu, animated: true, completion: nil)

    }

}

extension ApplicationController: SessionDelegate {
    func session(_ session: Session, didProposeVisitToURL URL: Foundation.URL, withAction action: Action) {
        presentVisitableForSession(session, URL: URL, action: action)
    }

    func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, withError error: NSError) {
        let alert = UIAlertController(title: "Error Requesting Data", message: "This data is temporarily unavailable. Please try again later.", preferredStyle: .alert)
        //alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
            self.popToRootViewController(animated: true)
        }))
        present(alert, animated: true, completion: nil)
    }

    func sessionDidStartRequest(_ session: Session) {
        application.isNetworkActivityIndicatorVisible = true

    }

    func sessionDidFinishRequest(_ session: Session) {
        application.isNetworkActivityIndicatorVisible = false
    }

}

extension ApplicationController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {

        // set the params from the js bridge message
        if let message = message.body as? String {
            //print(message)
            params = message
            if (app_type == "food") {
                food_params = params
            } else if (app_type == "study") {
                study_params = params
            } else if (app_type == "tech") {
                tech_params = params
            }
        }

    }

}
