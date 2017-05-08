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
    
    var touchDelta = CGPoint.zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //UIGestureRecognizer
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(ViewController.handlePan(_:)))
        joypadHead.addGestureRecognizer(panGesture)
        
        //Multipeer Connectivity
        
        //session
        self.myPeerID = MCPeerID(displayName: UIDevice.current.name)
        self.session = MCSession(peer: self.myPeerID, securityIdentity: nil, encryptionPreference: .required)
        self.session.delegate = self
        self.browser = MCBrowserViewController(serviceType: kServiceType, session: self.session)
        self.browser.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return .landscape
    }
    
    override var shouldAutorotate : Bool {
        return true
    }
    
    //MARK:- IBActions

    @IBAction func browseTapped(_ sender: AnyObject) {
    
        self.present(self.browser, animated: true, completion: nil)
    }
    
    @IBAction func actionTapped(_ sender: AnyObject) {
     
        let dict = ["type":"button", "index":NSNumber(value: 0 as Int32)] as [String : Any]
        let dictData = NSKeyedArchiver.archivedData(withRootObject: dict)
        
        do {
            try self.session.send(dictData, toPeers: self.session.connectedPeers, with: .reliable)
        } catch {
            print("error sending data")
        }
    }
    
    //MARK:- UIGestureRecognizers
    
    func handlePan(_ recognizer:UIPanGestureRecognizer) {
    
        let touchPoint = recognizer.location(in: self.view)
        
        if(recognizer.view == self.joypadHead) {
        
            if(recognizer.state == .began) {
        
                touchDelta = CGPoint(
                    x: touchPoint.x - self.joypadBase.center.x,
                    y: touchPoint.y - self.joypadBase.center.y)
            }
            else if(recognizer.state == .changed) {
            
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
                    self.joypadHead.center = CGPoint(
                        x: touchPoint.x - touchDelta.x,
                        y: touchPoint.y - touchDelta.y)
        
                } else {
                    
                    let maxRadius:Float = 70.5
                    
                    self.joypadHead.center = CGPoint(
                        x: self.joypadBase.center.x - CGFloat(cos(touchAngle) * maxRadius),
                        y: self.joypadBase.center.y - CGFloat(sin(touchAngle) * maxRadius))
                }
                
                if self.session.connectedPeers.count == 1 {
                
                    let dict = ["type":"move", "touchDistance":NSNumber(value: touchDistance as Float), "touchAngle":NSNumber(value: touchAngle as Float)] as [String : Any]
                    let dictData = NSKeyedArchiver.archivedData(withRootObject: dict)
                    
                    do {
                        try self.session.send(dictData, toPeers: self.session.connectedPeers, with: .reliable)
                    } catch {
                        print("error sending data")
                    }
                }
            }
            else if(recognizer.state == .ended) {
                
                UIView.animate(withDuration: 0.5, animations: { () -> Void in
                    
                    recognizer.view?.center = self.joypadBase.center
                })
            }
        }
    }
    
    //MARK:- Util
    
    func calcDistanceWithOrigin(_ origin:CGPoint, andDestination destination:CGPoint) -> CGFloat {
    
        let deltaX = destination.x - origin.x
        let deltaY = destination.y - origin.y
        
        return sqrt(deltaX * deltaX + deltaY * deltaY)
    }
    
    //MARK: - MCNearbyServiceBrowserDelegate
    
    func browserViewController(_ browserViewController: MCBrowserViewController, shouldPresentNearbyPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) -> Bool {
        
        print("peerID: \(peerID)")
        
        return true
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        
        print("browser finished")
        
        self.browser.dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        
        print("browser cancelled")
        
        self.browser.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - MCSessionDelegate
    
    func session(_ session: MCSession, didReceiveCertificate certificate: [AnyObject]?, fromPeer peerID: MCPeerID, certificateHandler: (Bool) -> Void) {
        
        return certificateHandler(true)
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
        print("myPeerID: \(self.session.myPeerID)")
        print("connectd peerID: \(peerID)")
        
        switch state {
            
        case .connecting:
            print("Connecting..")
            break
            
        case .connected:
            print("Connected..")
            
            DispatchQueue.main.async(execute: { () -> Void in
                
                self.statusLbl.text = self.kTextConnected
            })
            
            break
            
        case .notConnected:
            print("Not Connected..")
            
            DispatchQueue.main.async(execute: { () -> Void in
                
                self.statusLbl.text = self.kTextNotConnected
            })
            
            break
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        print("hand didReceiveData")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
        print("hand didStartReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        
        print("hand didFinishReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
        print("hand didReceiveStream")
    }
}

