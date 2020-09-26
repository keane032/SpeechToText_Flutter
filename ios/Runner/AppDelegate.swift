import UIKit
import Flutter
import Speech
import AVFoundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    
    let speechChannel = FlutterMethodChannel(name: "samples.flutter.dev/speech",
                                               binaryMessenger: controller.binaryMessenger)
    
    let audioController = AudioController();
    
     speechChannel.setMethodCallHandler({
        (call: FlutterMethodCall, result: FlutterResult) -> Void in
       
        if call.method == "speech" {
            audioController.recordAndRecognizeSpeech(method: speechChannel);
        }
        
        if call.method == "stop" {
            audioController.finishRecognize()
         }
        
     })

    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    
    }

}


class AudioController {
   
    var audioRecorder: AVAudioRecorder!
    var text = "default";
    var lastString = "default"
    
    var recordingSession: AVAudioSession!
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale(identifier: "pt-BR"))
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    
    var interval = 0;
    var time = Timer();
    
    func finishRecognize(){
        self.recognitionTask?.finish()
        self.audioEngine.stop()
    }
    
    func recordAndRecognizeSpeech(method: FlutterMethodChannel){
        
        checkPermissions()
        
        if(SFSpeechRecognizer.authorizationStatus() != .authorized){
            print("denid perission")
            return
        }
        
       let node = audioEngine.inputNode
       let recordingFormat = node.outputFormat(forBus: 0)
       node.removeTap(onBus: 0)
       node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat){
       buffer, _ in self.request.append(buffer)}
       audioEngine.prepare()
       
       do{
           try audioEngine.start()
       }catch{
            print("erro audio engine")
           return print(error)
       }
       
       guard let myRecording = SFSpeechRecognizer(locale: Locale(identifier: "pt-BR")) else {
           return
       }
        
       if !myRecording.isAvailable{
           return
       }
        
       recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: {
           result, error in
           if let result = result {
                self.text = result.bestTranscription.formattedString;
            
                self.interval = 0
                self.time.invalidate()
                
            if result.isFinal {
                return
              }
            
                self.time = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                           self.interval = self.interval+1
                            print("enter Number: \(self.interval)")
                           if(self.interval == 4){
                                self.time.invalidate()
                                self.finishRecognize()
                                print("stop time")
                           }
                       }
                
                method.invokeMethod("voice_text", arguments: self.text)
           } else if let error = error {
               print(error)
           }
       })
        
        self.interval = 0
        self.time.invalidate()

          self.time = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
              self.interval = self.interval+1
              print("out Number: \(self.interval)")
              if(self.interval == 5){
                  self.time.invalidate()
                  self.finishRecognize()
                  print("stop time")
              }
          }
    }
    
    private func checkPermissions() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    break
                case .denied:
                    break
                case .restricted:
                    break
                case .notDetermined:
                    break
                @unknown default:
                    fatalError()
                }
            }
        }
    }
    
    func startRecording() {
       
       checkPermissions()
       
       if(SFSpeechRecognizer.authorizationStatus() != .authorized){
           print("recorde")
           return
       }
       
       let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a");
       
         let settings = [
             AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
             AVSampleRateKey: 12000,
             AVNumberOfChannelsKey: 1,
             AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
         ]
       
         do {
           audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings);
           audioRecorder?.record()
           print("recorde de audio")

         } catch {
           print("falha")
         }
     }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func finishRecording(success: Bool, method: FlutterMethodChannel) -> String {
        audioRecorder = nil
        transcribeAudio(url: getDocumentsDirectory().appendingPathComponent("recording.m4a"), method: method)
        return self.text
    }
    
    func transcribeAudio(url: URL, method: FlutterMethodChannel) {
        
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "pt-BR"))
        let request = SFSpeechURLRecognitionRequest(url: url)
        
        recognizer?.recognitionTask(with: request) { (result, error) in
            guard let result = result else {
                print("There was an error: \(error!)")
                return
            }
            if result.isFinal {
                print("proxima linha ea resposta");
                print(result.bestTranscription.formattedString)
                self.text = result.bestTranscription.formattedString;
                method.invokeMethod("voice_text", arguments:self.text)
                return
            }
        }
    }
    
}
