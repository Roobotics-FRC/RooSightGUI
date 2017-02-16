//
//  ViewController.swift
//  RooSightGUI
//
//  Created by aaplmath on 2/15/17.
//  Copyright © 2017 aaplmath. All rights reserved.
//

import Cocoa

enum EditMode {
    case HSV, HSL, RGB
}

extension RangeSlider {
    var startInt: Int {
        get {
            return Int(self.start)
        }
    }
    var endInt: Int {
        get {
            return Int(self.end)
        }
    }
}

class ViewController: NSViewController {
    
    // MARK: - Outlets
    
    @IBOutlet var label1: NSTextField!
    @IBOutlet var label2: NSTextField!
    @IBOutlet var label3: NSTextField!
    
    @IBOutlet var slider1: RangeSlider!
    @IBOutlet var slider2: RangeSlider!
    @IBOutlet var slider3: RangeSlider!
    
    @IBOutlet var minLabel1: NSTextField!
    @IBOutlet var minLabel2: NSTextField!
    @IBOutlet var minLabel3: NSTextField!
    
    @IBOutlet var maxLabel1: NSTextField!
    @IBOutlet var maxLabel2: NSTextField!
    @IBOutlet var maxLabel3: NSTextField!
    
    @IBOutlet var imageView: NSImageView!
    var filePath: URL?
    
    var editMode: EditMode = .HSV {
        willSet(mode) {
            switch mode {
            case .HSV:
                label1.stringValue = "Hue"
                label2.stringValue = "Saturation"
                label3.stringValue = "Value"
            case .HSL:
                label1.stringValue = "Hue"
                label2.stringValue = "Saturation"
                label3.stringValue = "Luminance"
            case .RGB:
                label1.stringValue = "Red"
                label2.stringValue = "Green"
                label3.stringValue = "Blue"
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Prevent the ImageView from making the view massive
        imageView.setContentCompressionResistancePriority(NSLayoutPriority(1), for: .horizontal)
        
        // MARK: - Slider config
        slider1.minValue = 0
        slider1.maxValue = 255
        slider2.minValue = 0
        slider2.maxValue = 255
        slider3.minValue = 0
        slider3.maxValue = 255
        
        // MARK: Slider listeners
        slider1.onControlChanged = {
            slider in
            self.minLabel1.stringValue = String(slider.startInt)
            self.maxLabel1.stringValue = String(slider.endInt)
        }
        slider2.onControlChanged = {
            slider in
            self.minLabel2.stringValue = String(slider.startInt)
            self.maxLabel2.stringValue = String(slider.endInt)
        }
        slider3.onControlChanged = {
            slider in
            self.minLabel3.stringValue = String(slider.startInt)
            self.maxLabel3.stringValue = String(slider.endInt)
        }
    }
    
    // MARK: - Listeners

    @IBAction func didChangeMode(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0:
            editMode = .HSV
        case 1:
            editMode = .HSL
        case 2:
            editMode = .RGB
        default:
            generateError(withText: "Illegal mode selected.")
        }
    }
    
    @IBAction func uploadClicked(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["jpg"]
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = true
        if let window = self.view.window {
            openPanel.beginSheetModal(for: window) {
                (res: Int) in
                if res == NSFileHandlingPanelOKButton {
                    let selectedFile = openPanel.urls[0]
                    let image = NSImage(contentsOf: selectedFile)
                    self.imageView.image = image
                    self.filePath = selectedFile
                }
            }
        } else {
            generateError(withText: "Could not find window to start upload dialog.")
        }
    }
    
    @IBAction func renderClicked(_ sender: NSButton) {
        if let file = filePath {
            let slider1Min = slider1.startInt
            let slider1Max = slider1.endInt
            let slider2Min = slider2.startInt
            let slider2Max = slider2.endInt
            let slider3Min = slider3.startInt
            let slider3Max = slider3.endInt
            
            let process = Process()
            process.launchPath = "/usr/bin/java"
            if let protocolIndex = file.absoluteString.range(of: "file://")?.upperBound, let jarPath = Bundle.main.path(forResource: "RooSight-1.0", ofType: "jar") {
                let trimmedFileString = file.absoluteString.substring(from: protocolIndex)
                process.arguments = ["-Djava.library.path=/usr/local/Cellar/opencv3/3.2.0/share/OpenCV/java", "-jar", jarPath, "-file", trimmedFileString]
                switch editMode {
                case .HSV:
                    process.arguments!.append("-hsv")
                case .HSL:
                    process.arguments!.append("-hsl")
                case .RGB:
                    process.arguments!.append("-rgb")
                }
                process.arguments!.append("\(slider1Min),\(slider1Max),\(slider2Min),\(slider2Max),\(slider3Min),\(slider3Max)")
                process.terminationHandler = {
                    (terminatedProc: Process) in
                    let outPath = trimmedFileString + ".out.jpg"
                    DispatchQueue.main.async {
                        self.imageView.image = NSImage(contentsOfFile: outPath)
                        do {
                            try FileManager.default.removeItem(atPath: outPath)
                        } catch let e {
                            self.generateError(withText: "Could not delete outputted file. The following error was returned:\n\n" + e.localizedDescription)
                        }
                    }
                }
                process.launch()
            } else {
                DispatchQueue.main.async {
                    self.generateError(withText: "Found illegal URL format when locating image to render.")
                }
            }
        } else {
            generateError(withText: "There is no image to render!")
        }
    }
    
    @IBAction func generateCodeClicked(_ sender: NSButton) {
        var codeString = "RooConfig config = new RooConfig();\n"
        switch editMode {
        case .HSV:
            codeString += "config.setHSV"
        case .HSL:
            codeString += "config.setHSL"
        case .RGB:
            codeString += "config.setRGB"
        }
        codeString += "(\(slider1.startInt), \(slider1.endInt), \(slider2.startInt), \(slider2.endInt), \(slider3.startInt), \(slider3.endInt));"
        NSPasteboard.general().clearContents()
        NSPasteboard.general().setString(codeString, forType: NSPasteboardTypeString)
        let alert = NSAlert()
        alert.messageText = "Code Copied"
        alert.informativeText = "The generated code has been copied to the clipboard."
        alert.alertStyle = .informational
        if let window = self.view.window {
            alert.beginSheetModal(for: window, completionHandler: nil)
        } else {
            alert.runModal()
        }
    }
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    // MARK: - Utility functions
    
    func generateError(withText text: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = text
        alert.alertStyle = .warning
        if let window = self.view.window {
            alert.beginSheetModal(for: window, completionHandler: nil)
        } else {
            alert.runModal()
        }
    }


}

