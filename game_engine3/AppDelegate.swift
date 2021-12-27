//
//  AppDelegate.swift
//  game_engine3
//
//  Created by Apple1 on 4/6/21.
//

import Cocoa
import SwiftUI

var globalwindow:NSWindow?

@main
class AppDelegate:NSObject,NSApplicationDelegate{
    var window: NSWindow!
    func applicationDidFinishLaunching(_ aNotification: Notification){
        let contentView = ContentView()
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.isReleasedWhenClosed = true
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        
        globalwindow=window
 
    }
    func applicationWillTerminate(_ aNotification:Notification){}
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

