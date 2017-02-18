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

extension Array {
    func toParams() -> String {
        var str = ""
        for i in 0..<self.count {
            str += String(describing: self[i])
            if i != self.count - 1 {
                str += ","
            }
        }
        return str
    }
}

extension NSColor {
    func toParams() -> String {
        return "\(Int(self.redComponent * 255)),\(Int(self.greenComponent * 255)),\(Int(self.blueComponent * 255))"
    }
}

class ViewController: NSViewController {
    
    // MARK: - Outlets
    
    var hsv: [Int] = [0, 255, 0, 255, 0, 255]
    var hsl: [Int] = [0, 255, 0, 255, 0, 255]
    var rgb: [Int] = [0, 255, 0, 255, 0, 255]
    
    @IBOutlet var label1: NSTextField!
    @IBOutlet var label2: NSTextField!
    @IBOutlet var label3: NSTextField!
    
    @IBOutlet var modeSelect: NSSegmentedControl!
    
    @IBOutlet var slider1: RangeSlider!
    @IBOutlet var slider2: RangeSlider!
    @IBOutlet var slider3: RangeSlider!
    
    @IBOutlet var minLabel1: NSTextField!
    @IBOutlet var minLabel2: NSTextField!
    @IBOutlet var minLabel3: NSTextField!
    
    @IBOutlet var maxLabel1: NSTextField!
    @IBOutlet var maxLabel2: NSTextField!
    @IBOutlet var maxLabel3: NSTextField!
    
    @IBOutlet var minWidthField: NSTextField!
    @IBOutlet var maxWidthField: NSTextField!
    @IBOutlet var minHeightField: NSTextField!
    @IBOutlet var maxHeightField: NSTextField!
    @IBOutlet var minAreaField: NSTextField!
    @IBOutlet var maxAreaField: NSTextField!
    
    @IBOutlet var colorField: NSColorWell!
    
    @IBOutlet var imageView: NSImageView!
    var filePath: URL?
    
    var editMode: EditMode = .HSV {
        willSet(mode) {
            setColorValArrays()
            switch mode {
            case .HSV:
                label1.stringValue = "Hue"
                label2.stringValue = "Saturation"
                label3.stringValue = "Value"
                resetSliders(to: hsv)
            case .HSL:
                label1.stringValue = "Hue"
                label2.stringValue = "Saturation"
                label3.stringValue = "Luminance"
                resetSliders(to: hsl)
            case .RGB:
                label1.stringValue = "Red"
                label2.stringValue = "Green"
                label3.stringValue = "Blue"
                resetSliders(to: rgb)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Prevent the ImageView from making the view (and window) massive
        imageView.setContentCompressionResistancePriority(NSLayoutPriority(1), for: .horizontal)
        
        // MARK: - Slider config
        slider1.minValue = 0
        slider1.maxValue = 255
        slider2.minValue = 0
        slider2.maxValue = 255
        slider3.minValue = 0
        slider3.maxValue = 255
        
        slider1.snapsToIntegers = true
        slider2.snapsToIntegers = true
        slider3.snapsToIntegers = true
        
        // MARK: Slider listener bindings
        
        minLabel1.bind("integerValue", to: slider1, withKeyPath: "start", options: nil)
        maxLabel1.bind("integerValue", to: slider1, withKeyPath: "end", options: nil)
        minLabel2.bind("integerValue", to: slider2, withKeyPath: "start", options: nil)
        maxLabel2.bind("integerValue", to: slider2, withKeyPath: "end", options: nil)
        minLabel3.bind("integerValue", to: slider3, withKeyPath: "start", options: nil)
        maxLabel3.bind("integerValue", to: slider3, withKeyPath: "end", options: nil)
        
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
            let process = Process()
            process.launchPath = "/usr/bin/java"
            if let protocolIndex = file.absoluteString.range(of: "file://")?.upperBound, let jarPath = Bundle.main.path(forResource: "RooSightCLT-1.0.0", ofType: "jar") {
                let trimmedFileString = file.absoluteString.substring(from: protocolIndex)
                process.arguments = ["-jar", jarPath, "-i", trimmedFileString]
                setColorValArrays()
                process.arguments!.append(contentsOf: ["-hsv", hsv.toParams(), "-hsl", hsl.toParams(), "-rgb", rgb.toParams()])
                if minWidthField.stringValue != "" {
                    process.arguments!.append(contentsOf: ["-wmin", minWidthField.stringValue])
                }
                if maxWidthField.stringValue != "" {
                    process.arguments!.append(contentsOf: ["-wmax", maxWidthField.stringValue])
                }
                if minHeightField.stringValue != "" {
                    process.arguments!.append(contentsOf: ["-hmin", minHeightField.stringValue])
                }
                if maxHeightField.stringValue != "" {
                    process.arguments!.append(contentsOf: ["-hmax", maxHeightField.stringValue])
                }
                if minAreaField.stringValue != "" {
                    process.arguments!.append(contentsOf: ["-amin", minAreaField.stringValue])
                }
                if maxAreaField.stringValue != "" {
                    process.arguments!.append(contentsOf: ["-amax", maxAreaField.stringValue])
                }
                process.arguments!.append(contentsOf: ["-c", colorField.color.toParams()])
                let outPath = "/tmp/roo_output.jpg"
                process.arguments!.append(contentsOf: (["-o", outPath]))
                process.terminationHandler = {
                    (terminatedProc: Process) in
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
    
    @IBAction func resetClicked(_ sender: NSButton) {
        let alert = NSAlert()
        alert.messageText = "Confirm Reset"
        alert.informativeText = "Are you sure you want to reset the workspace? This will clear specified filter values, height/width/area values, contour color, and image."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        if let window = self.view.window {
            alert.beginSheetModal(for: window) {
                (res: NSModalResponse) in
                if (res == 1000) {
                    let resetArray = [0, 255, 0, 255, 0, 255]
                    self.hsv = resetArray
                    self.hsl = resetArray
                    self.rgb = resetArray
                    self.filePath = nil
                    self.resetSliders(to: resetArray)
                    self.minWidthField.stringValue = ""
                    self.maxWidthField.stringValue = ""
                    self.minHeightField.stringValue = ""
                    self.maxHeightField.stringValue = ""
                    self.minAreaField.stringValue = ""
                    self.maxAreaField.stringValue = ""
                    self.imageView.image = nil
                    self.colorField.color = NSColor.green
                    self.modeSelect.selectedSegment = 0
                }
            }
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
    
    func setColorValArrays() {
        let arr = [slider1.startInt, slider1.endInt, slider2.startInt, slider2.endInt, slider3.startInt, slider3.endInt]
        switch editMode {
        case .HSV:
            hsv = arr
        case .HSL:
            hsl = arr
        case .RGB:
            rgb = arr
        }
    }
    
    func resetSliders(to values: [Int]) {
        let doubles: [Double] = values.map { Double($0) }
        slider1.start = doubles[0]
        slider1.end = doubles[1]
        slider2.start = doubles[2]
        slider2.end = doubles[3]
        slider3.start = doubles[4]
        slider3.end = doubles[5]
    }
}

