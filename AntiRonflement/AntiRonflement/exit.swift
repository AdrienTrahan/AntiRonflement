//
//  exit.swift
//  AntiRonflement
//
//  Created by Antoine Trahan on 2019-03-02.
//  Copyright © 2019 InputBox Inc. All rights reserved.
//

import Foundation
import UIKit
class exitscreen : UIViewController{
    override func viewWillDisappear(_ animated: Bool) {
        self.dismiss(animated: true, completion: nil)
    }
}
