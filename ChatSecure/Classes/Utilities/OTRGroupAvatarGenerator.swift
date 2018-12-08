//
//  OTRGroupAvatarGenerator.swift
//  ChatSecure
//
//  Created by N-Pex on 2017-07-20.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import Foundation

open class OTRGroupAvatarGenerator {

    static let arrayOfColors:[CGColor] = [
        colorWithHexString(hexColorString: "#fff73d54").cgColor,
        colorWithHexString(hexColorString: "#fffff74f").cgColor,
        colorWithHexString(hexColorString: "#ffb2142f").cgColor,
        colorWithHexString(hexColorString: "#ff4fcaff").cgColor,
        colorWithHexString(hexColorString: "#ff86ff76").cgColor,
        colorWithHexString(hexColorString: "#ffcc4317").cgColor,
        colorWithHexString(hexColorString: "#ff8376ff").cgColor
    ]
    
    public static func avatarImage(withSeed seed: String, width: Int, height: Int) -> UIImage? {
        
        // Create a pseudo-random random number generator and seed it with the identifier
        // hash. This will ensure that we get the same image every time we call it with
        // the same identifier!
        let generator = LinearCongruentialGenerator(seed: seed.javaHash())
        let range = 0.3 * Double(height)
        let halfrange = Int(range / 2)
        let a = Int(generator.random() * range) - halfrange
        let b = Int(generator.random() * range) - halfrange
        let c = Int(generator.random() * range) - halfrange
        let d = Int(generator.random() * range) - halfrange
        
        let colorTop = arrayOfColors[Int(generator.random() *  Double(arrayOfColors.count))]
        let colorMiddle = arrayOfColors[Int(generator.random() * Double(arrayOfColors.count))]
        let colorBottom = arrayOfColors[Int(generator.random() * Double(arrayOfColors.count))]
        
        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        if let ctx = UIGraphicsGetCurrentContext() {
            // Middle part (just fill all)
            ctx.setFillColor(colorMiddle)
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

            let aThird = Int(0.33 * Double(height))
            let twoThirds = Int(0.66 * Double(height))
            
            // Top third
            ctx.setFillColor(colorTop)
            ctx.move(to: CGPoint(x: 0, y: 0))
            ctx.addLine(to: CGPoint(x: 0, y: aThird + a))
            ctx.addLine(to: CGPoint(x: width, y: aThird + c))
            ctx.addLine(to: CGPoint(x: width, y: 0))
            ctx.addLine(to: CGPoint(x: 0, y: 0))
            ctx.drawPath(using: .fill)
            
            // Bottom third
            ctx.setFillColor(colorBottom)
            ctx.move(to: CGPoint(x: 0, y: twoThirds + b))
            ctx.addLine(to: CGPoint(x: 0, y: height))
            ctx.addLine(to: CGPoint(x: width, y: height))
            ctx.addLine(to: CGPoint(x: width, y: twoThirds + d))
            ctx.addLine(to: CGPoint(x: 0, y: twoThirds + b))
            ctx.drawPath(using: .fill)
        }
        let newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return newImage
    }
    
    public static func avatarTopColor(withSeed seed: String) -> CGColor {
        let generator = LinearCongruentialGenerator(seed: seed.javaHash())
        return arrayOfColors[Int(generator.random(at: 5) * Double(arrayOfColors.count))]
    }
    
    static func colorWithHexString(hexColorString:String) -> UIColor {
        let scanner = Scanner(string: hexColorString)
        scanner.scanLocation = 1
        var rgb: UInt32 = 0
        guard scanner.scanHexInt32(&rgb) else { return UIColor.white }
        let a:CGFloat = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
        let r:CGFloat = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
        let g:CGFloat = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
        let b:CGFloat = CGFloat(rgb & 0x000000FF) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    
    // A LCG to create pseudo-random numbers (using a seed)
    //
    // Inspired by: https://stackoverflow.com/questions/24027216/how-do-you-generate-a-random-number-in-swift
    class LinearCongruentialGenerator {
        var lastRandom = 0.0
        let m = 139968.0
        let a = 3877.0
        let c = 29573.0
        
        public init(seed: Int) {
            let doubleSeed = abs(Double(seed))
            self.lastRandom = ((doubleSeed * a + c).truncatingRemainder(dividingBy: m))
        }
        
        public func random() -> Double {
            lastRandom = ((lastRandom * a + c).truncatingRemainder(dividingBy: m))
            return lastRandom / m
        }
        
        public func random(at: Int) -> Double {
            var ret:Double = 0
            for _ in 0..<at {
                ret = random()
            }
            return ret
        }
    }
}

// An extension to return a java-compatible hash of a string
// See for example: http://grepcode.com/file/repository.grepcode.com/java/root/jdk/openjdk/6-b14/java/lang/String.java#String.hashCode%28%29
extension String {
    func javaHash() -> Int {
        var hash:Int32 = 0
        for char in self.utf16 {
            let lhs: Int32 = Int32(31).multipliedReportingOverflow(by: hash).0
            let rhs: Int32 = Int32(UInt(char))
            hash = lhs.addingReportingOverflow(rhs).0
        }
        return Int(hash)
    }
}
