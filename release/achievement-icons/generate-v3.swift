import AppKit
import Foundation

// Run with: swift release/achievement-icons/generate-v3.swift
// Creates 20 circular 1024x1024 RGBA badges with -v3 filenames.
// Existing assets are never overwritten.

private struct Icon {
    let identifier: String
    let category: String
    let value: String
    let caption: String
    let accent: NSColor
    let secondary: NSColor
}

private func color(_ hex: UInt32) -> NSColor {
    NSColor(
        calibratedRed: CGFloat((hex >> 16) & 0xff) / 255,
        green: CGFloat((hex >> 8) & 0xff) / 255,
        blue: CGFloat(hex & 0xff) / 255,
        alpha: 1
    )
}

private let icons: [Icon] = [
    Icon(identifier: "othello.cpu.easy", category: "CPU 勝利", value: "ひよっこ", caption: "やさしい をクリア", accent: color(0x42D6AA), secondary: color(0x138773)),
    Icon(identifier: "othello.cpu.normal", category: "CPU 勝利", value: "一人前", caption: "ふつう をクリア", accent: color(0x66B8FF), secondary: color(0x2466B7)),
    Icon(identifier: "othello.cpu.strong", category: "CPU 勝利", value: "達人", caption: "つよい をクリア", accent: color(0xC299FF), secondary: color(0x7846C5)),
    Icon(identifier: "othello.cpu.oni", category: "CPU 勝利", value: "レジェンド", caption: "おに をクリア", accent: color(0xFFB356), secondary: color(0xD94E57)),
    Icon(identifier: "othello.streak.3", category: "連戦連勝", value: "3", caption: "3 連勝", accent: color(0xFFC663), secondary: color(0xDF7D3E)),
    Icon(identifier: "othello.streak.5", category: "連戦連勝", value: "5", caption: "5 連勝", accent: color(0xFFB35B), secondary: color(0xD96837)),
    Icon(identifier: "othello.streak.10", category: "連戦連勝", value: "10", caption: "10 連勝", accent: color(0xFFA260), secondary: color(0xCB4F49)),
    Icon(identifier: "othello.streak.15", category: "連戦連勝", value: "15", caption: "15 連勝", accent: color(0xFF8E75), secondary: color(0xB94161)),
    Icon(identifier: "othello.streak.20", category: "連戦連勝", value: "20", caption: "20 連勝", accent: color(0xFF7D91), secondary: color(0xAF396D)),
    Icon(identifier: "othello.streak.25", category: "連戦連勝", value: "25", caption: "25 連勝", accent: color(0xF079AB), secondary: color(0x963F87)),
    Icon(identifier: "othello.streak.30", category: "連戦連勝", value: "30", caption: "30 連勝", accent: color(0xE993F3), secondary: color(0x854BB6)),
    Icon(identifier: "othello.wins.1", category: "通算勝利", value: "1", caption: "通算 1 勝", accent: color(0x7CEBD4), secondary: color(0x159A91)),
    Icon(identifier: "othello.wins.3", category: "通算勝利", value: "3", caption: "通算 3 勝", accent: color(0x69E0C5), secondary: color(0x119A85)),
    Icon(identifier: "othello.wins.5", category: "通算勝利", value: "5", caption: "通算 5 勝", accent: color(0x5CDBAF), secondary: color(0x158E6B)),
    Icon(identifier: "othello.wins.10", category: "通算勝利", value: "10", caption: "通算 10 勝", accent: color(0x9CE074), secondary: color(0x529638)),
    Icon(identifier: "othello.wins.30", category: "通算勝利", value: "30", caption: "通算 30 勝", accent: color(0xC6DF6F), secondary: color(0x87953D)),
    Icon(identifier: "othello.wins.100", category: "通算勝利", value: "100", caption: "通算 100 勝", accent: color(0xE7D475), secondary: color(0xAD8B34)),
    Icon(identifier: "othello.wins.1000", category: "通算勝利", value: "1000", caption: "通算 1000 勝", accent: color(0xF5BE7C), secondary: color(0xB77830)),
    Icon(identifier: "othello.wins.10000", category: "通算勝利", value: "10000", caption: "通算 10000 勝", accent: color(0xFFDDA1), secondary: color(0xBD9A43)),
    Icon(identifier: "othello.two_player.101", category: "2 人対戦", value: "101", caption: "友達100人できるかな", accent: color(0xFF95CF), secondary: color(0x7A80EB))
].filter { !$0.identifier.hasPrefix("othello.cpu.") }

private let destination = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
private let fileManager = FileManager.default
private let cpuIDs = ["othello.cpu.easy", "othello.cpu.normal", "othello.cpu.strong", "othello.cpu.oni"]
for identifier in icons.map(\.identifier) + cpuIDs {
    let file = destination.appendingPathComponent(identifier + "-v3.png")
    guard !fileManager.fileExists(atPath: file.path) else {
        fputs("Already exists; refusing to overwrite: \(file.path)\n", stderr)
        exit(1)
    }
}

private func rounded(_ rect: NSRect, radius: CGFloat, fill: NSColor) {
    fill.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}

private func centered(_ text: String, y: CGFloat, maxWidth: CGFloat, initialSize: CGFloat, color: NSColor, weight: NSFont.Weight = .heavy) {
    var fontSize = initialSize
    var font = NSFont.systemFont(ofSize: fontSize, weight: weight)
    var attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
    var size = (text as NSString).size(withAttributes: attributes)
    while size.width > maxWidth && fontSize > 40 {
        fontSize -= 2
        font = NSFont.systemFont(ofSize: fontSize, weight: weight)
        attributes[.font] = font
        size = (text as NSString).size(withAttributes: attributes)
    }
    (text as NSString).draw(at: NSPoint(x: (1024 - size.width) / 2, y: y), withAttributes: attributes)
}

private func circle(x: CGFloat, y: CGFloat, radius: CGFloat, fill: NSColor) {
    fill.setFill()
    NSBezierPath(ovalIn: NSRect(x: x - radius, y: y - radius,
                              width: radius * 2, height: radius * 2)).fill()
}

private func categorySymbol(for icon: Icon, y: CGFloat, scale: CGFloat) {
    let isStreak = icon.identifier.hasPrefix("othello.streak.")
    let isWins = icon.identifier.hasPrefix("othello.wins.")
    if isStreak {
        let line = NSBezierPath()
        line.move(to: NSPoint(x: 512 - 75 * scale, y: y))
        line.line(to: NSPoint(x: 512 + 75 * scale, y: y))
        line.lineWidth = 9 * scale
        line.lineCapStyle = .round
        icon.accent.setStroke()
        line.stroke()
        for offset in [-75, 0, 75] {
            circle(x: 512 + CGFloat(offset) * scale, y: y,
                   radius: 23 * scale, fill: .white)
            circle(x: 512 + CGFloat(offset) * scale, y: y,
                   radius: 10 * scale, fill: color(0x132C38))
        }
    } else if isWins {
        // A compact trophy silhouette communicates accumulated victories.
        let cup = NSBezierPath()
        cup.move(to: NSPoint(x: 512 - 55 * scale, y: y + 32 * scale))
        cup.line(to: NSPoint(x: 512 + 55 * scale, y: y + 32 * scale))
        cup.line(to: NSPoint(x: 512 + 35 * scale, y: y - 18 * scale))
        cup.line(to: NSPoint(x: 512 - 35 * scale, y: y - 18 * scale))
        cup.close()
        icon.accent.setFill()
        cup.fill()
        let stem = NSRect(x: 512 - 9 * scale, y: y - 48 * scale,
                          width: 18 * scale, height: 37 * scale)
        stem.fill()
        rounded(NSRect(x: 512 - 47 * scale, y: y - 56 * scale,
                       width: 94 * scale, height: 12 * scale),
                radius: 6 * scale, fill: icon.accent)
        for side in [-1, 1] {
            let handle = NSBezierPath()
            handle.move(to: NSPoint(x: 512 + CGFloat(side) * 48 * scale, y: y + 22 * scale))
            handle.line(to: NSPoint(x: 512 + CGFloat(side) * 77 * scale, y: y + 19 * scale))
            handle.line(to: NSPoint(x: 512 + CGFloat(side) * 55 * scale, y: y - 4 * scale))
            handle.lineWidth = 9 * scale
            handle.lineCapStyle = .round
            icon.accent.setStroke()
            handle.stroke()
        }
    } else {
        // Two opposing black and white reversi stones represent local play.
        circle(x: 512 - 60 * scale, y: y, radius: 39 * scale, fill: .white)
        circle(x: 512 + 60 * scale, y: y, radius: 39 * scale, fill: icon.accent)
        circle(x: 512 + 60 * scale, y: y, radius: 25 * scale, fill: color(0x071A23))
    }
}

private func draw(_ icon: Icon) -> Data {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: 1024,
        pixelsHigh: 1024,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        fatalError("Could not create image context")
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: 1024, height: 1024).fill()

    let background = NSRect(x: 20, y: 20, width: 984, height: 984)
    let backgroundPath = NSBezierPath(ovalIn: background)
    backgroundPath.addClip()
    NSGradient(starting: color(0x122D38), ending: color(0x071922))!
        .draw(in: backgroundPath, angle: -90)

    // An eight-by-eight board stays visible behind the central stone.
    let boardOrigin = NSPoint(x: 112, y: 115)
    let tile: CGFloat = 100
    for row in 0..<8 {
        for column in 0..<8 {
            let tone = (row + column).isMultiple(of: 2) ? 0.11 : 0.19
            NSColor(calibratedWhite: 1, alpha: tone).setFill()
            NSRect(x: boardOrigin.x + CGFloat(column) * tile,
                   y: boardOrigin.y + CGFloat(row) * tile,
                   width: tile - 5, height: tile - 5).fill()
        }
    }

    // Category frame and double-sided reversi stone.
    rounded(NSRect(x: 300, y: 835, width: 424, height: 104), radius: 52, fill: color(0x081D29))
    let medallion = NSBezierPath(ovalIn: NSRect(x: 191, y: 228, width: 642, height: 642))
    NSGradient(starting: icon.accent, ending: icon.secondary)!.draw(in: medallion, angle: -70)
    let blackStone = NSBezierPath(ovalIn: NSRect(x: 222, y: 260, width: 580, height: 580))
    NSGradient(starting: color(0x263E49), ending: color(0x091B24))!.draw(in: blackStone, angle: -90)
    NSColor(calibratedWhite: 1, alpha: 0.13).setStroke()
    blackStone.lineWidth = 5
    blackStone.stroke()
    NSColor(calibratedWhite: 1, alpha: 0.10).setFill()
    NSBezierPath(ovalIn: NSRect(x: 292, y: 663, width: 440, height: 119)).fill()
    NSColor(calibratedWhite: 1, alpha: 0.95).setFill()
    NSBezierPath(ovalIn: NSRect(x: 459, y: 687, width: 106, height: 106)).fill()
    NSColor(calibratedWhite: 0.08, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: 484, y: 712, width: 56, height: 56)).fill()

    categorySymbol(for: icon, y: 883, scale: 0.62)
    centered(icon.value, y: 418, maxWidth: 570, initialSize: 275, color: .white)
    categorySymbol(for: icon, y: 340, scale: 0.72)
    rounded(NSRect(x: 300, y: 89, width: 424, height: 122), radius: 61, fill: color(0x071A23))
    categorySymbol(for: icon, y: 150, scale: 0.56)

    let outerRim = NSBezierPath(ovalIn: NSRect(x: 27, y: 27, width: 970, height: 970))
    icon.accent.withAlphaComponent(0.90).setStroke()
    outerRim.lineWidth = 11
    outerRim.stroke()

    NSGraphicsContext.current?.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Could not encode PNG")
    }
    return data
}

for icon in icons {
    let file = destination.appendingPathComponent(icon.identifier + "-v3.png")
    do {
        try draw(icon).write(to: file, options: .withoutOverwriting)
        print(file.path)
    } catch {
        fputs("Failed to write \(file.path): \(error)\n", stderr)
        exit(1)
    }
}

// The four character medals already have circular compositions. Preserve their
// artwork and add an exact alpha circle, leaving a 20px transparent margin.
for identifier in cpuIDs {
    let source = destination.appendingPathComponent(identifier + "-v2.png")
    let output = destination.appendingPathComponent(identifier + "-v3.png")
    guard let image = NSImage(contentsOf: source),
          let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: 1024, pixelsHigh: 1024,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
            isPlanar: false, colorSpaceName: .deviceRGB,
            bytesPerRow: 0, bitsPerPixel: 0),
          let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        fatalError("Could not load CPU medal: \(source.path)")
    }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: 1024, height: 1024).fill()
    NSBezierPath(ovalIn: NSRect(x: 20, y: 20, width: 984, height: 984)).addClip()
    image.draw(in: NSRect(x: 0, y: 0, width: 1024, height: 1024))
    NSGraphicsContext.current?.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Could not encode CPU medal: \(identifier)")
    }
    do {
        try data.write(to: output, options: .withoutOverwriting)
        print(output.path)
    } catch {
        fputs("Failed to write \(output.path): \(error)\n", stderr)
        exit(1)
    }
}
