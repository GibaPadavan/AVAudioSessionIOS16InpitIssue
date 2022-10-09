//
//  ViewController.swift
//  AVAudioSessionIOS16InpitIssue
//
//  Created by Andrey Gibadullin on 09.10.2022.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet var outputText: UITextView!
    let outputPipe = Pipe()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        captureStandardOutputAndRouteToTextView()
        setupAudioSession()
    }
    
    func captureStandardOutputAndRouteToTextView() {
        dup2(self.outputPipe.fileHandleForWriting.fileDescriptor, FileHandle.standardOutput.fileDescriptor)
        
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading , queue: nil) {
          notification in
          
          let output = self.outputPipe.fileHandleForReading.availableData
          let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
          
          DispatchQueue.main.async(execute: {
            let previousOutput = self.outputText.text ?? ""
            let nextOutput = previousOutput + outputString
            self.outputText.text = nextOutput
            
            let range = NSRange(location:nextOutput.count,length:0)
            self.outputText.scrollRangeToVisible(range)
          })
          
          self.outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        }
    }

    func setupAudioSession() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord, options: .mixWithOthers)
            try audioSession.setActive(true, options: [])
        } catch {
            print("AVAudioSession init error: \(error)")
        }
       
    }

    @objc func handleRouteChange(notification: Notification) {
        print("\nHANDLE ROUTE CHANGE")
        print("AVAILABLE INPUTS: \(AVAudioSession.sharedInstance().availableInputs ?? [])")
        print("PREFERRED INPUT: \(String(describing: AVAudioSession.sharedInstance().preferredInput))")
        print("CURRENT ROUTE: \(AVAudioSession.sharedInstance().currentRoute)\n")
    }

    @IBAction func selectPreferredInputClick(_ sender: UIButton) {
        let inputs = AVAudioSession.sharedInstance().availableInputs ?? []
        let title = "Select Preferred Input"
        let message = "Current Preferred Input: \(String(describing: AVAudioSession.sharedInstance().preferredInput?.portName))\nCurrent Route Input \(String(describing: AVAudioSession.sharedInstance().currentRoute.inputs.first?.portName))"
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        for input in inputs {
            alert.addAction(UIAlertAction(title: input.portName, style: .default) {_ in
                print("\n\(title)")
                print("\(message) New Preferred Input: \(input.portName)\n")
                do {
                    try AVAudioSession.sharedInstance().setPreferredInput(input)
                } catch {
                    print("Set Preferred Input Error: \(error)")
                }
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

