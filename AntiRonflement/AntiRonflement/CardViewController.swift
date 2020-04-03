//
//  CardViewController.swift
//  AntiRonflement
//
//  Created by Antoine Trahan on 2019-03-02.
//  Copyright © 2019 InputBox Inc. All rights reserved.
//
import Foundation
import UIKit

class CardViewController: UIViewController {
    
    @IBOutlet weak var handleArea: UIView!
    
    @IBOutlet var sensSlider: UISlider!
    @IBOutlet var notSlider: UISlider!
    @IBOutlet var quaSlider: UISlider!
    @IBOutlet var sensLbl: UILabel!
    @IBOutlet var sensReset: UIButton!
    @IBOutlet var notLbl: UILabel!
    @IBOutlet var notReset: UIButton!
    @IBOutlet var quaLbl: UILabel!
    @IBOutlet var quaReset: UIButton!
    
    @IBAction func updateSens(_ sender: Any) {
        userDefault.set(sensSlider.value, forKey: "sens")
        sens = Int(sensSlider.value)
    }
    @IBAction func updateNot(_ sender: Any) {
        userDefault.set(notSlider.value, forKey: "not")
        not = Int(notSlider.value)
    }
    @IBAction func updateQua(_ sender: Any) {
        userDefault.set(quaSlider.value, forKey: "qua")
        qua = Int(quaSlider.value)
    }
    @IBAction func resetSens(_ sender: Any) {
        userDefault.set(30, forKey: "sens")
        sens = 30
        sensSlider.value = 30
    }
    @IBAction func resetNot(_ sender: Any) {
        userDefault.set(30, forKey: "not")
        not = 15
        notSlider.value = 30
    }
    @IBAction func resetQua(_ sender: Any) {
        userDefault.set(30, forKey: "qua")
        qua = 30
        quaSlider.value = 30
    }
    
    
    
    
    var userDefault = UserDefaults.standard
    
    override func viewWillAppear(_ animated: Bool) {
        if userDefault.integer(forKey: "sens") == 0{
            userDefault.set(30, forKey: "sens")
            sens = 30
            sensSlider.value = 30
        }else{
            sens = userDefault.integer(forKey: "sens")
            sensSlider.value = Float(userDefault.integer(forKey: "sens"))
        }
        if userDefault.integer(forKey: "not") == 0{
            userDefault.set(30, forKey: "not")
            not = 15
            notSlider.value = 30
        }else{
            not = userDefault.integer(forKey: "not")
            notSlider.value = Float(userDefault.integer(forKey: "not"))
        }
        if userDefault.integer(forKey: "qua") == 0{
            userDefault.set(30, forKey: "qua")
            qua = 30
            quaSlider.value = 30
        }else{
            qua = userDefault.integer(forKey: "qua")
            quaSlider.value = Float(userDefault.integer(forKey: "qua"))
        }
    }
    
}
