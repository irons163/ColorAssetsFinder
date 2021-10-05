//
//  main.swift
//  ColorAssetsFinder
//
//  Created by Phil on 2021/9/22.
//

import Foundation

// Test case
//let file = "PATH_TO_PROJECT/Assets.xcassets/Color/LEDOrangeColor.colorset/Contents.json"
//let targetColor = "FF7C00"
//var targetColorComponentsArray: [String] = []
//
//for i in stride(from: 0, to: targetColor.count, by: 2) {
//    let startIndex = targetColor.index(targetColor.startIndex, offsetBy: i)
//    let subStr = targetColor[startIndex...targetColor.index(startIndex, offsetBy: 1)]
//    targetColorComponentsArray.append("0x\(subStr)")
//}
//print(findColorInFile(URL.init(fileURLWithPath: file), toFindColor: targetColor, targetColorComponentsArray: targetColorComponentsArray))


let assetsFolder = "PATH_TO_PROJECT/Assets.xcassets" // Input source path: Assets.xcassets
var targetColor = "#E4EAEF" // Color format can be 6 digit Hex or with # in the beginning.
let isDarkMode = true // Find targetColor in dark mode colors

if targetColor.hasPrefix("#") {
    targetColor = String(targetColor[targetColor.index(after: targetColor.startIndex) ..< targetColor.endIndex])
}

print("Target Color:\(targetColor)")
print("isDarkMode:\(isDarkMode)")

passFolder(assetsFolder, toFindColor: targetColor)

func passFolder(_ file: String, toFindColor color: String) {
    let localFileManager = FileManager.default
    let resourceKeys = Set<URLResourceKey>([.isDirectoryKey])
    let directoryURL = URL.init(string: assetsFolder)!
    let directoryEnumerator = localFileManager.enumerator(at: directoryURL, includingPropertiesForKeys: Array(resourceKeys), options: .skipsHiddenFiles)!
     
    var targetColorComponentsArray: [String] = []

    for i in stride(from: 0, to: targetColor.count, by: 2) {
        let startIndex = targetColor.index(targetColor.startIndex, offsetBy: i)
        let subStr = targetColor[startIndex...targetColor.index(startIndex, offsetBy: 1)]
        targetColorComponentsArray.append("0x\(subStr)")
    }
    
    var foundColorNamesArray: [String] = []
    for case let fileURL as URL in directoryEnumerator {
        guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
            let isDirectory = resourceValues.isDirectory
            else {
                continue
        }
        
        if !isDirectory {
            if fileURL.lastPathComponent == "Contents.json" {
                foundColorNamesArray.append(contentsOf: findColorInFile(fileURL, toFindColor: targetColor, targetColorComponentsArray: targetColorComponentsArray))
            }
        }
    }
    
    print("foundColorNames:\(foundColorNamesArray)")
}

func findColorInFile(_ file: URL, toFindColor color: String, targetColorComponentsArray: [String]) -> [String] {
    var path = file
    var foundColorNamesArray = [String]()
    do {
        let data = try Data.init(contentsOf: path)
        let json = try JSONSerialization.jsonObject(with: data, options:[]) as! Dictionary<String, Any>
        var isExist = true
        for i in 0..<targetColorComponentsArray.count {
            let targetColorComponent = targetColorComponentsArray[i]
            let colors = json["colors"] as? Array<Dictionary<String, Any>>
            if colors == nil {
                return []
            }
            
            var color: Dictionary<String, Any>?
            if isDarkMode {
                switch colors!.count {
                case 1:
                    break
                case 2:
                    color = colors?[1]["color"] as? Dictionary<String, Any>
                case 3:
                    color = colors?[2]["color"] as? Dictionary<String, Any>
                default:
                    break
                }
            } else {
                color = colors?[0]["color"] as? Dictionary<String, Any>
            }
            
            if color == nil {
                return []
            }
            
            let components = color?["components"]
            let redComponent = (components as! Dictionary<String, Any>)["red"] as! String
            let greenComponent = (components as! Dictionary<String, Any>)["green"] as! String
            let blueComponent = (components as! Dictionary<String, Any>)["blue"] as! String
            
            switch i {
            case 0:
                if targetColorComponent != redComponent {
                    isExist = false
                }
            case 1:
                if targetColorComponent != greenComponent {
                    isExist = false
                }
            case 2:
                if targetColorComponent != blueComponent {
                    isExist = false
                }
            default: break
            }
        }
        
        if isExist {
            path.deleteLastPathComponent()
            foundColorNamesArray.append(path.lastPathComponent)
        }
    } catch {
        print("Failed.")
    }
    
    return foundColorNamesArray
}
