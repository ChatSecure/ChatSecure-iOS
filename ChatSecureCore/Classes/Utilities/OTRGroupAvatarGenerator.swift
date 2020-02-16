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
        colorWithHexString(hexColorString: "#f73d54").cgColor,
        colorWithHexString(hexColorString: "#fff74f").cgColor,
        colorWithHexString(hexColorString: "#b2142f").cgColor,
        colorWithHexString(hexColorString: "#4fcaff").cgColor,
        colorWithHexString(hexColorString: "#86ff76").cgColor,
        colorWithHexString(hexColorString: "#cc4317").cgColor,
        colorWithHexString(hexColorString: "#8376ff").cgColor
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
        UIColor(hexString: hexColorString)
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

extension UIColor {

    // https://stackoverflow.com/a/38909348
    convenience init(hexString: String, alpha: Double = 1.0) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (1, 1, 0)
        }

        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(255 * alpha) / 255)
    }

}
