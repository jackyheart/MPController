//
//  ViewController.swift
//  MPController
//
//  Created by Jacky Tjoa on 1/12/15.
//  Copyright © 2015 Coolheart. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, MCBrowserViewControllerDelegate, MCSessionDelegate {

    @IBOutlet weak var joypadBase: UIImageView!
    @IBOutlet weak var joypadHead: UIImageView!
    @IBOutlet weak var btnAction: UIButton!
    @IBOutlet weak var statusLbl: UILabel!
    
    //UI
    let kTextNotConnected = "Not Connected"
    let kTextConnected = "Connected"
    
    //Multipeer Connectivity
    let kServiceType = "multi-peer-chat"
    var myPeerID:MCPeerID!
    var session:MCSession!
    var browser:MCBrowserViewController!
    
    var touchDelta = CGPointZero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //UIGestureRecognizer
        let panGesture = UIPanGestureRecognizer(target: self, action: "handlePan:")
        joypadHead.addGestureRecognizer(panGesture)
        
        //Multipeer Connectivity
        
        //session
        self.myPeerID = MCPeerID(displayName: UIDevice.currentDevice().name)
        self.session = MCSession(peer: self.myPeerID, securityIdentity: nil, encryptionPreference: .Required)
        self.session.delegate = self
        self.browser = MCBrowserViewController(serviceType: kServiceType, session: self.session)
        self.browser.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Landscape
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    //MARK:- IBActions

    @IBAction func browseTapped(sender: AnyObject) {
    
        self.presentViewController(self.browser, animated: true, completion: nil)
    }
    
    @IBAction func actionTapped(sender: AnyObject) {
     
        let dict = ["type":"button", "index":NSNumber(int: 0)]
        let dictData = NSKeyedArchiver.archivedDataWithRootObject(dict)
        
        do {
            try self.session.sendData(dictData, toPeers: self.session.connectedPeers, withMode: .Reliable)
        } catch {
            print("error sending data")
        }
    }
    
    //MARK:- UIGestureRecognizers
    
    func handlePan(recognizer:UIPanGestureRecognizer) {
    
        let touchPoint = recognizer.locationInView(self.view)
        
        if(recognizer.view == self.joypadHead) {
        
            if(recognizer.state == .Began) {
        
                touchDelta = CGPointMake(
                    touchPoint.x - self.joypadBase.center.x,
                    touchPoint.y - self.joypadBase.center.y)
            }
            else if(recognizer.state == .Changed) {
            
                let diffFromBaseX = self.joypadHead.center.x - self.joypadBase.center.x
                let diffFromBaseY = self.joypadHead.center.y - self.joypadBase.center.y
                let radius = sqrt(diffFromBaseX * diffFromBaseX + diffFromBaseY * diffFromBaseY)
                
                print("touchDelta: \(touchDelta)")
                print("diffX: \(diffFromBaseX)")
                print("diffY: \(diffFromBaseY)")
                print("radius: \(radius)")
                print("\n")
                
                let dx = self.joypadBase.center.x - touchPoint.x
                let dy = self.joypadBase.center.y - touchPoint.y
                
                let touchDistance:Float = Float(self.calcDistanceWithOrigin(self.joypadBase.center, andDestination: self.joypadHead.center))
                let touchAngle:Float = Float(atan2(dy, dx))
                
                if (radius < 70)
                {
                    self.joypadHead.center = CGPointMake(
                        touchPoint.x - touchDelta.x,
                        touchPoint.y - touchDelta.y)
        
                } else {
                    
                    let maxRadius:Float = 70.5
                    
                    self.joypadHead.center = CGPointMake(
                        self.joypadBase.center.x - CGFloat(cos(touchAngle) * maxRadius),
                        self.joypadBase.center.y - CGFloat(sin(touchAngle) * maxRadius))
                }
                
                if self.session.connectedPeers.count == 1 {
                
                    let dict = ["type":"move", "touchDistance":NSNumber(float: touchDistance), "touchAngle":NSNumber(float: touchAngle)]
                    let dictData = NSKeyedArchiver.archivedDataWithRootObject(dict)
                    
                    do {
                        try self.session.sendData(dictData, toPeers: self.session.connectedPeers, withMode: .Reliable)
                    } catch {
                        print("error sending data")
                    }
                }
            }
            else if(recognizer.state == .Ended) {
                
                UIView.animateWithDuration(0.5, animations: { () -> Void in
                    
                    recognizer.view?.center = self.joypadBase.center
                })
            }
        }
    }
    
    //MARK:- Util
    
    func calcDistanceWithOrigin(origin:CGPoint, andDestination destination:CGPoint) -> CGFloat {
    
        let deltaX = destination.x - origin.x
        let deltaY = destination.y - origin.y
        
        return sqrt(deltaX * deltaX + deltaY * deltaY)
    }
    
    //MARK: - MCNearbyServiceBrowserDelegate
    
    func browserViewController(browserViewController: MCBrowserViewController, shouldPresentNearbyPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) -> Bool {
        
        print("peerID: \(peerID)")
        
        return true
    }
    
    func browserViewControllerDidFinish(browserViewController: MCBrowserViewController) {
        
        print("browser finished")
        
        self.browser.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(browserViewController: MCBrowserViewController) {
        
        print("browser cancelled")
        
        self.browser.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: - MCSessionDelegate
    
    func session(session: MCSession, didReceiveCertificate certificate: [AnyObject]?, fromPeer peerID: MCPeerID, certificateHandler: (Bool) -> Void) {
        
        return certificateHandler(true)
    }
    
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        
        print("myPeerID: \(self.session.myPeerID)")
        print("connectd peerID: \(peerID)")
        
        switch state {
            
        case .Connecting:
            print("Connecting..")
            break
            
        case .Connected:
            print("Connected..")
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                self.statusLbl.text = self.kTextConnected
            })
            
            break
            
        case .NotConnected:
            print("Not Connected..")
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                self.statusLbl.text = self.kTextNotConnected
            })
            
            break
        }
    }
    
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        
        print("hand didReceiveData")
    }
    
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
        
        print("hand didStartReceivingResourceWithName")
    }
    
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        
        print("hand didFinishReceivingResourceWithName")
    }
    
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
        print("hand didReceiveStream")
    }
}

