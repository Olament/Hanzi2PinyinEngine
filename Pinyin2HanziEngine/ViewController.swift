//
//  ViewController.swift
//  Pinyin2HanziEngine
//
//  Created by Zixuan on 2/8/20.
//  Copyright © 2020 Zixuan. All rights reserved.
//

import UIKit
import Foundation

class ViewController: UIViewController {
    
    let model: PinyinEngine = PinyinEngine()
    
    @IBOutlet weak var input: UITextField!
    @IBOutlet weak var output: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    @IBAction func getSentence(_ sender: UIButton) {
        if let inputString = input.text {
            let start = DispatchTime.now()
            let solutions = model.getSentence(pinyin: inputString)
            let end = DispatchTime.now()
            let elapsedTime = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
            print("Time: \(elapsedTime)")
            
            output.text = ""
            for solution in solutions {
                output.text.append("\(solution.sentence) \(solution.probability)\n")
            }
        }
    }
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        input.resignFirstResponder()
    }
}

