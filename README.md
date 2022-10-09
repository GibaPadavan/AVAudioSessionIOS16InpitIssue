# AVAudioSessionIOS16InpitIssue
This is an example project to illustrate AVAudioSession input issues in iOS 16.

Here we create a playAndRecord AVAudioSession and subscribe for routeChangeNotification notification:

```swift
NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
let audioSession = AVAudioSession.sharedInstance()
do {
  try audioSession.setCategory(AVAudioSession.Category.playAndRecord, options: .mixWithOthers)
  try audioSession.setActive(true, options: [])
} catch {
  print("AVAudioSession init error: \(error)")
}
```
When we get a notification - we print the list of available audio inputs, preferred input and current audio route:

```swift
@objc func handleRouteChange(notification: Notification) {
  print("\nHANDLE ROUTE CHANGE")
  print("AVAILABLE INPUTS: \(AVAudioSession.sharedInstance().availableInputs ?? [])")
  print("PREFERRED INPUT: \(String(describing: AVAudioSession.sharedInstance().preferredInput))")
  print("CURRENT ROUTE: \(AVAudioSession.sharedInstance().currentRoute)\n")
}
```
And we have a button that displays an alert with the list of all available audio inputs and providing the way to set each input as preferred:

```swift
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
```


