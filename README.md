# AVAudioSessionIOS16InpitIssue

### UPDATE:
Apple released iOS 16.1 ad it looks that this issue is fixed there.

### What this is about:
I have an iOS "Guitar Effect" app that gets audio signal from input, process it and plays the result audio back to user via output. The app dosn't work with BuiltIn microphone of iOS device (because of feedback) - users have to connect guitar via special device: either analog like [iRig](https://www.ikmultimedia.com/products/irig2/?pkey=irig-2) or digital like [iRig HD](https://www.ikmultimedia.com/products/irighd2/?pkey=irig-hd-2).

**TL;DR:** Starting from iOS 16 I face a weird behaviour of the AVAudioSession that breaks my app. In iOS 16 the input of the AVAudioSession Route is always MicrophoneBuiltIn - no matter if I connect any external microphones like iRig device or headphones with microphone. Even if I try to manually switch to external microphone by assigning the preferredInput for AVAudioSession it doesn't change the route - input is always MicrophoneBuiltIn. In iOS 15 and earlier iOS automatically change the input of the route to any external microphone you attach to the iOS device. And you may control the input by assigning preferredInput property for AVAudioSession.

This is an smallest example project to reproduce the issue.

### Project Structure:

This is a very small project created to reproduce the issue. All the code is in ViewController class.

1) I create a playAndRecord AVAudioSession and subscribe for routeChangeNotification notification:

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
2) When I get a notification - I print the list of available audio inputs, preferred input and current audio route:

```swift
@objc func handleRouteChange(notification: Notification) {
  print("\nHANDLE ROUTE CHANGE")
  print("AVAILABLE INPUTS: \(AVAudioSession.sharedInstance().availableInputs ?? [])")
  print("PREFERRED INPUT: \(String(describing: AVAudioSession.sharedInstance().preferredInput))")
  print("CURRENT ROUTE: \(AVAudioSession.sharedInstance().currentRoute)\n")
}
```
3) I have a button that displays an alert with the list of all available audio inputs and providing the way to set each input as preferred:

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

### iOS 16 Behaviour:

When I launch the app without any external mics attached and initiate the AVAudioSession I have the following log:

```
HANDLE ROUTE CHANGE
AVAILABLE INPUTS: [<AVAudioSessionPortDescription: 0x2837101e0, type = MicrophoneBuiltIn; name = iPhone Microphone; UID = Built-In Microphone; selectedDataSource = Bottom>]
PREFERRED INPUT: nil
CURRENT ROUTE: <AVAudioSessionRouteDescription: 0x283710a80, 
inputs = (
    "<AVAudioSessionPortDescription: 0x283710a50, type = MicrophoneBuiltIn; name = iPhone Microphone; UID = Built-In Microphone; selectedDataSource = Bottom>"
); 
outputs = (
    "<AVAudioSessionPortDescription: 0x283710600, type = Receiver; name = Receiver; UID = Built-In Receiver; selectedDataSource = (null)>"
)>
```
This is perfectly fine. Then I attach the iRig device (which is basically the external microphone) and I have the following log:

```
HANDLE ROUTE CHANGE
AVAILABLE INPUTS: [<AVAudioSessionPortDescription: 0x283718630, type = MicrophoneBuiltIn; name = iPhone Microphone; UID = Built-In Microphone; selectedDataSource = Bottom>, <AVAudioSessionPortDescription: 0x283718500, type = MicrophoneWired; name = Headset Microphone; UID = Wired Microphone; selectedDataSource = (null)>]
PREFERRED INPUT: nil
CURRENT ROUTE: <AVAudioSessionRouteDescription: 0x283700140, 
inputs = (
    "<AVAudioSessionPortDescription: 0x283700160, type = MicrophoneBuiltIn; name = iPhone Microphone; UID = Built-In Microphone; selectedDataSource = Bottom>"
); 
outputs = (
    "<AVAudioSessionPortDescription: 0x2837001f0, type = Headphones; name = Headphones; UID = Wired Headphones; selectedDataSource = (null)>"
)>
```
As you see - the MicrophoneWired appears in the list of available inputs but input of the route is still MicrophoneBuiltIn.
Then I tried to change preferredInput of the AVAudioSession first to MicrophoneWired, then to MicrophoneBuiltIn and then to MicrophoneWired again:

```
Select Preferred Input
Current Preferred Input: nil
Current Route Input Optional("iPhone Microphone") New Preferred Input: Headset Microphone


Select Preferred Input
Current Preferred Input: Optional("Headset Microphone")
Current Route Input Optional("iPhone Microphone") New Preferred Input: iPhone Microphone


HANDLE ROUTE CHANGE
AVAILABLE INPUTS: [<AVAudioSessionPortDescription: 0x28299da70, type = MicrophoneBuiltIn; name = iPhone Microphone; UID = Built-In Microphone; selectedDataSource = Bottom>, <AVAudioSessionPortDescription: 0x28299d930, type = MicrophoneWired; name = Headset Microphone; UID = Wired Microphone; selectedDataSource = (null)>]
PREFERRED INPUT: Optional(<AVAudioSessionPortDescription: 0x282994330, type = MicrophoneBuiltIn; name = iPhone Microphone; UID = Built-In Microphone; selectedDataSource = Bottom>)
CURRENT ROUTE: <AVAudioSessionRouteDescription: 0x2829912d0, 
inputs = (
    "<AVAudioSessionPortDescription: 0x282991820, type = MicrophoneBuiltIn; name = iPhone Microphone; UID = Built-In Microphone; selectedDataSource = Bottom>"
); 
outputs = (
    "<AVAudioSessionPortDescription: 0x282991740, type = Headphones; name = Headphones; UID = Wired Headphones; selectedDataSource = (null)>"
)>


Select Preferred Input
Current Preferred Input: Optional("iPhone Microphone")
Current Route Input Optional("iPhone Microphone") New Preferred Input: Headset Microphone


HANDLE ROUTE CHANGE
AVAILABLE INPUTS: [<AVAudioSessionPortDescription: 0x28299d7c0, type = MicrophoneBuiltIn; name = iPhone Microphone; UID = Built-In Microphone; selectedDataSource = Bottom>, <AVAudioSessionPortDescription: 0x28299d8c0, type = MicrophoneWired; name = Headset Microphone; UID = Wired Microphone; selectedDataSource = (null)>]
PREFERRED INPUT: Optional(<AVAudioSessionPortDescription: 0x2829918e0, type = MicrophoneWired; name = Headset Microphone; UID = Wired Microphone; selectedDataSource = (null)>)
CURRENT ROUTE: <AVAudioSessionRouteDescription: 0x28299d530, 
inputs = (
    "<AVAudioSessionPortDescription: 0x28299d510, type = MicrophoneBuiltIn; name = iPhone Microphone; UID = Built-In Microphone; selectedDataSource = Bottom>"
); 
outputs = (
    "<AVAudioSessionPortDescription: 0x28299d6d0, type = Headphones; name = Headphones; UID = Wired Headphones; selectedDataSource = (null)>"
)>
```

No matter what is preferredInput the input device of AudioSession route is MicrophoneBuiltIn

### iOS 15 Behaviour:

Everything is different (and much better) in iOS 15. When I launch the app without any external mics attached and initiate the AVAudioSession I have the same log as I have on iOS 16:

```
HANDLE ROUTE CHANGE
AVAILABLE INPUTS: [<AVAudioSessionPortDescription: 0x2813cc930, type = MicrophoneBuiltIn; name = iPad Microphone; UID = Built-In Microphone; selectedDataSource = Top>]
PREFERRED INPUT: nil
CURRENT ROUTE: <AVAudioSessionRouteDescription: 0x2813cc9c0, 
inputs = (
    "<AVAudioSessionPortDescription: 0x2813cc9b0, type = MicrophoneBuiltIn; name = iPad Microphone; UID = Built-In Microphone; selectedDataSource = Top>"
); 
outputs = (
    "<AVAudioSessionPortDescription: 0x2813cc6b0, type = Speaker; name = Speaker; UID = Speaker; selectedDataSource = (null)>"
)>
```
Then I attach the iRig device (which is basically the external microphone) and I have the following log:

```
HANDLE ROUTE CHANGE
AVAILABLE INPUTS: [<AVAudioSessionPortDescription: 0x2813d0450, type = MicrophoneBuiltIn; name = iPad Microphone; UID = Built-In Microphone; selectedDataSource = Top>, <AVAudioSessionPortDescription: 0x2813d04a0, type = MicrophoneWired; name = YC136 USB AUDIO; UID = AppleUSBAudioEngine:Generic:YC136 USB AUDIO:20170726905926:2; selectedDataSource = (null)>]
PREFERRED INPUT: nil
CURRENT ROUTE: <AVAudioSessionRouteDescription: 0x2813e40f0, 
inputs = (
    "<AVAudioSessionPortDescription: 0x2813e4110, type = MicrophoneWired; name = YC136 USB AUDIO; UID = AppleUSBAudioEngine:Generic:YC136 USB AUDIO:20170726905926:2; selectedDataSource = (null)>"
); 
outputs = (
    "<AVAudioSessionPortDescription: 0x2813e4150, type = Headphones; name = YC136 USB AUDIO; UID = AppleUSBAudioEngine:Generic:YC136 USB AUDIO:20170726905926:1; selectedDataSource = (null)>"
)>


HANDLE ROUTE CHANGE
AVAILABLE INPUTS: [<AVAudioSessionPortDescription: 0x2813e40e0, type = MicrophoneBuiltIn; name = iPad Microphone; UID = Built-In Microphone; selectedDataSource = Top>, <AVAudioSessionPortDescription: 0x2813e4160, type = MicrophoneWired; name = YC136 USB AUDIO; UID = AppleUSBAudioEngine:Generic:YC136 USB AUDIO:20170726905926:2; selectedDataSource = (null)>]
PREFERRED INPUT: nil
CURRENT ROUTE: <AVAudioSessionRouteDescription: 0x2813dc1c0, 
inputs = (
    "<AVAudioSessionPortDescription: 0x2813dc1e0, type = MicrophoneWired; name = YC136 USB AUDIO; UID = AppleUSBAudioEngine:Generic:YC136 USB AUDIO:20170726905926:2; selectedDataSource = (null)>"
); 
outputs = (
    "<AVAudioSessionPortDescription: 0x2813dc220, type = Headphones; name = YC136 USB AUDIO; UID = AppleUSBAudioEngine:Generic:YC136 USB AUDIO:20170726905926:1; selectedDataSource = (null)>"
)>
```

Two major differences here:
1) routeChangeNotification was called two times
2) input of the AVAudioSession route is MicrophoneWired
Then I try to change the preferred input of the AVAudioSession and have the following log:

```
Select Preferred Input
Current Preferred Input: nil
Current Route Input Optional("YC136 USB AUDIO") New Preferred Input: iPad Microphone


HANDLE ROUTE CHANGE
AVAILABLE INPUTS: [<AVAudioSessionPortDescription: 0x2813c8db0, type = MicrophoneBuiltIn; name = iPad Microphone; UID = Built-In Microphone; selectedDataSource = Top>, <AVAudioSessionPortDescription: 0x2813c8e00, type = MicrophoneWired; name = YC136 USB AUDIO; UID = AppleUSBAudioEngine:Generic:YC136 USB AUDIO:20170726905926:2; selectedDataSource = (null)>]
PREFERRED INPUT: Optional(<AVAudioSessionPortDescription: 0x2813d8ad0, type = MicrophoneBuiltIn; name = iPad Microphone; UID = Built-In Microphone; selectedDataSource = Top>)
CURRENT ROUTE: <AVAudioSessionRouteDescription: 0x2813c0c40, 
inputs = (
    "<AVAudioSessionPortDescription: 0x2813c1300, type = MicrophoneBuiltIn; name = iPad Microphone; UID = Built-In Microphone; selectedDataSource = Top>"
); 
outputs = (
    "<AVAudioSessionPortDescription: 0x2813c10b0, type = Headphones; name = YC136 USB AUDIO; UID = AppleUSBAudioEngine:Generic:YC136 USB AUDIO:20170726905926:1; selectedDataSource = (null)>"
)>


Select Preferred Input
Current Preferred Input: Optional("iPad Microphone")
Current Route Input Optional("iPad Microphone") New Preferred Input: YC136 USB AUDIO


HANDLE ROUTE CHANGE
AVAILABLE INPUTS: [<AVAudioSessionPortDescription: 0x2813c0d50, type = MicrophoneBuiltIn; name = iPad Microphone; UID = Built-In Microphone; selectedDataSource = Top>, <AVAudioSessionPortDescription: 0x2813c0a20, type = MicrophoneWired; name = YC136 USB AUDIO; UID = AppleUSBAudioEngine:Generic:YC136 USB AUDIO:20170726905926:2; selectedDataSource = (null)>]
PREFERRED INPUT: Optional(<AVAudioSessionPortDescription: 0x2813e4140, type = MicrophoneWired; name = YC136 USB AUDIO; UID = AppleUSBAudioEngine:Generic:YC136 USB AUDIO:20170726905926:2; selectedDataSource = (null)>)
CURRENT ROUTE: <AVAudioSessionRouteDescription: 0x2813cdaa0, 
inputs = (
    "<AVAudioSessionPortDescription: 0x2813cdad0, type = MicrophoneWired; name = YC136 USB AUDIO; UID = AppleUSBAudioEngine:Generic:YC136 USB AUDIO:20170726905926:2; selectedDataSource = (null)>"
); 
outputs = (
    "<AVAudioSessionPortDescription: 0x2813cdeb0, type = Headphones; name = YC136 USB AUDIO; UID = AppleUSBAudioEngine:Generic:YC136 USB AUDIO:20170726905926:1; selectedDataSource = (null)>"
)>
```

As you see, the input of the route matches the preferred input of the AVAudioSession
