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

class DiscoverViewController: ApplicationController {
    
    override var URL: Foundation.URL {
        return Foundation.URL(string: "\(host)\(campus)/")!
    }
    
    // discover visit controller
    override func presentVisitableForSession(_ session: Session, URL: Foundation.URL, action: Action = .Advance) {
        let visitable = VisitableViewController(url: URL)
        
        // handle actions
        if action == .Advance {
            pushViewController(visitable, animated: true)
        } else if action == .Replace {
            popViewController(animated: true)
            //pushViewController(visitable, animated: false)
            setViewControllers([visitable], animated: false)
        }
        
        session.visit(visitable)
        
    }
    
    
}
