/*******************************************************************************
 * The MIT License (MIT)
 * 
 * Copyright (c) 2017 DigiDNA - www.digidna.net
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 ******************************************************************************/

import Cocoa
import GitHubUpdates

@NSApplicationMain class ApplicationDelegate: NSObject, NSApplicationDelegate
{
    @objc @IBOutlet private dynamic var updater: GitHubUpdater?
    
    @objc private dynamic var aboutWindowController: AboutWindowController?
    @objc private dynamic var controllers:           [ FileWindowController ] = []
    
    @objc private func windowWillClose( _ notification: Notification )
    {
        let window = notification.object as! NSWindow
        
        for controller in self.controllers
        {
            if( controller.window == window )
            {
                self.controllers = self.controllers.filter { controller != $0 }
                
                break;
            }
        }
    }
    
    // MARK: NSApplicationDelegate
    
    func applicationDidFinishLaunching( _ notification: Notification )
    {
        self.openDocument( nil )
        self.updater?.checkForUpdatesInBackground()
        
        Timer.scheduledTimer( withTimeInterval: 3600, repeats: true )
        {
            ( timer: Timer ) -> Void in
            
            self.updater?.checkForUpdatesInBackground()
        }
    }
    
    // MARK: Actions
    
    @IBAction public func showAboutWindow( _ sender: Any? )
    {
        if( self.aboutWindowController == nil )
        {
            self.aboutWindowController = AboutWindowController()
        }
        
        if( self.aboutWindowController?.window?.isVisible == false )
        {
            self.aboutWindowController?.window?.center()
        }
        
        self.aboutWindowController?.window?.makeKeyAndOrderFront( sender )
    }
    
    @IBAction public func openDocument( _ sender: Any? )
    {
        let panel = NSOpenPanel()
        
        panel.canChooseDirectories    = false
        panel.canCreateDirectories    = false
        panel.canChooseFiles          = true
        panel.allowsMultipleSelection = true
        
        if( panel.runModal() != .OK )
        {
            return
        }
        
        for url in panel.urls
        {
            let controller = FileWindowController( url: url )
            
            NotificationCenter.default.addObserver( self, selector: #selector( windowWillClose( _: ) ), name: NSWindow.willCloseNotification, object: controller.window )
            self.controllers.append( controller )
            controller.window?.center()
            controller.showWindow( nil )
        }
    }
}
