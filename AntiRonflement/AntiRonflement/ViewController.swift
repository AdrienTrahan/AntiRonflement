//
//  ViewController.swift
//  AntiRonflement
//
//  Created by Antoine Trahan on 2019-03-01.
//  Copyright © 2019 InputBox Inc. All rights reserved.
//

import UIKit
import GoogleMobileAds
import AVFoundation
var sens = 30
var not = 15
var qua = 30

class ViewController: UIViewController, AVAudioRecorderDelegate, GADRewardBasedVideoAdDelegate{

    
    
    enum CardState {
        case expanded
        case collapsed
    }
    var rewardBasedVideo: GADRewardBasedVideoAd?
    var cardViewController:CardViewController!
    var visualEffectView:UIVisualEffectView!
    
    let cardHeight:CGFloat = 363
    let cardHandleAreaHeight:CGFloat = 65
    
    var cardVisible = false
    var nextState:CardState {
        return cardVisible ? .collapsed : .expanded
    }
    
    var runningAnimations = [UIViewPropertyAnimator]()
    var animationProgressWhenInterrupted:CGFloat = 0
    
    
    
    @IBOutlet var Missing: UITextView!
    var recordingSession:AVAudioSession!
    var audioRecorder:AVAudioRecorder!
    var recordNb = 0
    var updateTimer: Timer?
    var isOn = false
    var count = 0
    
    @IBOutlet var button: UIButton!
    
    @IBOutlet var StateLbl: UILabel!
    
    var userDefault = UserDefaults.standard
    
    
    override func viewWillAppear(_ animated: Bool) {
        GADRewardBasedVideoAd.sharedInstance().load(GADRequest(), withAdUnitID: "ca-app-pub-8152105874972316/8919105809")
        GADRewardBasedVideoAd.sharedInstance().delegate = self
        
        if userDefault.integer(forKey: "sens") == 0{
            userDefault.set(30, forKey: "sens")
            sens = 30
        }else{
            sens = userDefault.integer(forKey: "sens")
        }
        if userDefault.integer(forKey: "not") == 0{
            userDefault.set(30, forKey: "not")
            not = 15
        }else{
            not = userDefault.integer(forKey: "not")
        }
        if userDefault.integer(forKey: "qua") == 0{
            userDefault.set(20, forKey: "qua")
            qua = 20
        }else{
            qua = userDefault.integer(forKey: "qua")
        }
        
        self.setupCard()
        self.cardViewController.view.alpha = 0
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { (timer) in
            if self.userDefault.integer(forKey: "demo") == 0{
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "demo")
                self.present(vc!, animated: true, completion: {
                    self.userDefault.set(1, forKey: "demo")
                })
            }else{
                self.Missing.alpha = 0
                self.button.alpha = 0
                self.StateLbl.alpha = 0
                self.cardViewController.view.alpha = 0
                self.recordingSession = AVAudioSession.sharedInstance()
                    AVAudioSession.sharedInstance().requestRecordPermission { (hasPermission) in
                        
                        if (hasPermission){
                            print("accepted!")
                            UIView.animate(withDuration: 0.5, animations: {
                                self.button.alpha = 1
                                self.StateLbl.alpha = 1
                                self.cardViewController.view.alpha = 1
                                self.Missing.alpha = 0
                            })
                            if self.audioRecorder != nil{
                                self.isOn = true
                                self.button.setBackgroundImage(UIImage(named: "powerOn.png"), for: .normal)
                                self.StateLbl.text = "Le détecteur de ronflements est en marche"
                                self.StateLbl.textColor = UIColor(red:0.20, green:0.73, blue:0.33, alpha:1.0)
                            }else{
                                self.isOn = false
                                self.button.setBackgroundImage(UIImage(named: "powerOff.png"), for: .normal)
                                self.StateLbl.text = "Le détecteur de ronflements est en arrêt"
                                self.StateLbl.textColor = UIColor(red:0.84, green:0.22, blue:0.25, alpha:1.0)
                            }
                        }else{
                            UIView.animate(withDuration: 0.5, animations: {
                                self.button.alpha = 0
                                self.StateLbl.alpha = 0
                                self.cardViewController.view.alpha = 0
                                self.Missing.alpha = 1
                            })
                            
                        }
                    }
                }
            }
                
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        
    }
    
    
    func Stop(){
        audioRecorder = nil
        if self.audioRecorder != nil{
            self.isOn = true
            self.button.setBackgroundImage(UIImage(named: "powerOn.png"), for: .normal)
            self.StateLbl.text = "The snoring detector is on"
            self.StateLbl.textColor = UIColor(red:0.20, green:0.73, blue:0.33, alpha:1.0)
        }else{
            self.isOn = false
            self.button.setBackgroundImage(UIImage(named: "powerOff.png"), for: .normal)
            self.StateLbl.text = "The snoring detector is off"
            self.StateLbl.textColor = UIColor(red:0.84, green:0.22, blue:0.25, alpha:1.0)
        }
    }
    
    
    
    @IBAction func Start(_ sender: Any) {
        if GADRewardBasedVideoAd.sharedInstance().isReady == true {
            GADRewardBasedVideoAd.sharedInstance().present(fromRootViewController: self)
        }
        start2(string: "second")
        
        
    }
    func start2(string:String){
        AVAudioSession.sharedInstance().requestRecordPermission { (hasPermission) in
            if (hasPermission){
                if self.isOn {
                    self.Stop()
                }else{
                    self.startRecording(string:string)
                }
            }else{
                
                
                
                print("refused!")
                
                
            }
        }
    }
    func startRecording(string: String){
        if (audioRecorder == nil){
            recordNb += 1
            count = 0
            let filename = getDirectory().appendingPathComponent("\(recordNb).m4a")
            let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 12000, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
            do{
                audioRecorder = try AVAudioRecorder(url: filename, settings: settings)
                audioRecorder.delegate = self
                audioRecorder.isMeteringEnabled = true
                audioRecorder.record()
                if (string == "second"){
                    Stop()
                    start2(string: "")
                }
                
                
                
                print("recording")
                OperationQueue().addOperation({[weak self] in
                    repeat {
                        self!.audioRecorder.updateMeters()
                        var averagePower = self!.audioRecorder.averagePower(forChannel: 0)
                        var peakPower = self!.audioRecorder.peakPower(forChannel: 0)
                        if (Int(averagePower) > sens * -1){
                            print("wakeUP")
                            self!.count += 1
                            if self!.count > qua{
                                
                                
                                for i in 0...not{
                                self!.sendAlert(fromNow: i)
                                }
                                self!.count = 0
                            }
                        }else{
                            print("dream")
                            self!.count -= 1/2
                        }
                        Thread.sleep(forTimeInterval: 0.5)
                    }
                        while (self!.audioRecorder != nil)
                })
                if self.audioRecorder != nil{
                    self.isOn = true
                    self.button.setBackgroundImage(UIImage(named: "powerOn.png"), for: .normal)
                    self.StateLbl.text = "The snoring detector is on"
                    self.StateLbl.textColor = UIColor(red:0.20, green:0.73, blue:0.33, alpha:1.0)
                }else{
                    self.isOn = false
                    self.button.setBackgroundImage(UIImage(named: "powerOff.png"), for: .normal)
                    self.StateLbl.text = "The snoring detector is off"
                    self.StateLbl.textColor = UIColor(red:0.84, green:0.22, blue:0.25, alpha:1.0)
                }
            }catch{
                print(error)
                if string != "last"{
                    startRecording(string: "last")
                }
                
            }
        }
    }
    
    
    
    func getDirectory() -> URL{
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = paths[0]
        return documentDirectory
    }
    
    func logC(val: Double, forBase base: Double) -> Double {
        return log(val)/log(base)
    }
    
    
    func sendAlert(fromNow: Int){
        DispatchQueue.main.async {
            let notification = UILocalNotification()
            notification.alertBody = "Wake Up"
            notification.alertAction = "open"
            notification.fireDate =  Date(timeIntervalSinceNow: TimeInterval(fromNow))
            notification.soundName = UILocalNotificationDefaultSoundName
            notification.userInfo = ["title": "Wake Up", "UUID": "232434"]
            print("sent")
            UIApplication.shared.scheduleLocalNotification(notification)
        }
        
    }
    
    
    
    func setupCard() {
        
        visualEffectView = UIVisualEffectView()
        visualEffectView.frame = self.view.frame
        self.view.addSubview(visualEffectView)
        visualEffectView.isHidden = true
        
        
        
        cardViewController = CardViewController(nibName:"CardViewController", bundle:nil)
        self.addChild(cardViewController)
        self.view.addSubview(cardViewController.view)
        cardViewController.view.frame.size.width = self.view.frame.size.width
        cardViewController.view.center.y = self.view.frame.size.height + cardHeight / 2 + 20
        self.cardViewController.view.frame.origin.y = self.view.frame.height - self.cardHandleAreaHeight - 20
        cardViewController.view.clipsToBounds = true
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleCardTap(recognzier:)))
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ViewController.handleCardPan(recognizer:)))
        
        cardViewController.handleArea.addGestureRecognizer(tapGestureRecognizer)
        cardViewController.handleArea.addGestureRecognizer(panGestureRecognizer)
        cardViewController.sensSlider.alpha = 0
        cardViewController.notSlider.alpha = 0
        cardViewController.quaSlider.alpha = 0
        cardViewController.sensLbl.alpha = 0
        cardViewController.notLbl.alpha = 0
        cardViewController.quaLbl.alpha = 0
        cardViewController.sensReset.alpha = 0
        cardViewController.notReset.alpha = 0
        cardViewController.quaReset.alpha = 0
        
    }
    
    @objc
    func handleCardTap(recognzier:UITapGestureRecognizer) {
        switch recognzier.state {
        case .ended:
            animateTransitionIfNeeded(state: nextState, duration: 0.9)
        default:
            break
        }
    }
    
    @objc
    func handleCardPan (recognizer:UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            startInteractiveTransition(state: nextState, duration: 0.9)
        case .changed:
            let translation = recognizer.translation(in: self.cardViewController.handleArea)
            var fractionComplete = translation.y / cardHeight
            fractionComplete = cardVisible ? fractionComplete : -fractionComplete
            updateInteractiveTransition(fractionCompleted: fractionComplete)
        case .ended:
            continueInteractiveTransition()
        default:
            break
        }
        
    }
    func animateTransitionIfNeeded (state:CardState, duration:TimeInterval) {
        if runningAnimations.isEmpty {
            let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.cardViewController.view.frame.origin.y = self.view.frame.height - self.cardHeight
                    UIView.animate(withDuration: 0.5, animations: {
                        self.cardViewController.sensSlider.alpha = 1
                        self.cardViewController.notSlider.alpha = 1
                        self.cardViewController.quaSlider.alpha = 1
                        self.cardViewController.sensLbl.alpha = 1
                        self.cardViewController.notLbl.alpha = 1
                        self.cardViewController.quaLbl.alpha = 1
                        self.cardViewController.sensReset.alpha = 1
                        self.cardViewController.notReset.alpha = 1
                        self.cardViewController.quaReset.alpha = 1
                    })
                case .collapsed:
                    self.cardViewController.view.frame.origin.y = self.view.frame.height - self.cardHandleAreaHeight - 20
                    UIView.animate(withDuration: 0.5, animations: {
                        self.cardViewController.sensSlider.alpha = 0
                        self.cardViewController.notSlider.alpha = 0
                        self.cardViewController.quaSlider.alpha = 0
                        self.cardViewController.sensLbl.alpha = 0
                        self.cardViewController.notLbl.alpha = 0
                        self.cardViewController.quaLbl.alpha = 0
                        self.cardViewController.sensReset.alpha = 0
                        self.cardViewController.notReset.alpha = 0
                        self.cardViewController.quaReset.alpha = 0
                    })
                }
            }
            
            frameAnimator.addCompletion { _ in
                self.cardVisible = !self.cardVisible
                self.runningAnimations.removeAll()
            }
            
            frameAnimator.startAnimation()
            runningAnimations.append(frameAnimator)
            
            
            let cornerRadiusAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
                switch state {
                case .expanded:
                    self.cardViewController.view.layer.cornerRadius = 12
                case .collapsed:
                    self.cardViewController.view.layer.cornerRadius = 0
                }
            }
            
            cornerRadiusAnimator.startAnimation()
            runningAnimations.append(cornerRadiusAnimator)
            
            let blurAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.visualEffectView.effect = UIBlurEffect(style: .dark)
                    self.visualEffectView.isHidden = false
                case .collapsed:
                    self.visualEffectView.effect = nil
                    self.visualEffectView.isHidden = true
                }
            }
            
            blurAnimator.startAnimation()
            runningAnimations.append(blurAnimator)
            
        }
    }
    
    func startInteractiveTransition(state:CardState, duration:TimeInterval) {
        if runningAnimations.isEmpty {
            animateTransitionIfNeeded(state: state, duration: duration)
        }
        for animator in runningAnimations {
            animator.pauseAnimation()
            animationProgressWhenInterrupted = animator.fractionComplete
        }
    }
    
    func updateInteractiveTransition(fractionCompleted:CGFloat) {
        for animator in runningAnimations {
            animator.fractionComplete = fractionCompleted + animationProgressWhenInterrupted
        }
    }
    
    func continueInteractiveTransition (){
        for animator in runningAnimations {
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        }
    }
    func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd,
                            didFailToLoadWithError error: Error) {
        print("Reward based video ad failed to load: \(error.localizedDescription)")
    }
    
    func rewardBasedVideoAdDidReceive(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        print("Reward based video ad is received.")
    }
    
    func rewardBasedVideoAdDidOpen(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        print("Opened reward based video ad.")
    }
    
    func rewardBasedVideoAdDidStartPlaying(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        print("Reward based video ad started playing.")
    }
    
    func rewardBasedVideoAdDidClose(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        print("Reward based video ad is closed.")
    }
    
    func rewardBasedVideoAdWillLeaveApplication(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        print("Reward based video ad will leave application.")
    }
    
    func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd,
                            didRewardUserWith reward: GADAdReward) {
        print("Reward received with currency:  amount).")
    }
}

