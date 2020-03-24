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

@objc class FileWindowController: NSWindowController, NSTextFieldDelegate
{
    @objc private dynamic var url:  URL?
    @objc private dynamic var file: String?
    @objc private dynamic var icon: NSImage?
    @objc private dynamic var box:  BoxItem?
    
    @objc private dynamic var loading:       Bool = false
    @objc private dynamic var showASCIIData: Bool = false
    
    @objc @IBOutlet private dynamic var outlineView:          NSOutlineView?
    @objc @IBOutlet private dynamic var treeController:       NSTreeController?
    @objc @IBOutlet private dynamic var dictionaryController: NSDictionaryController?
    @objc @IBOutlet private dynamic var searchField:          NSSearchField?
    @objc @IBOutlet private dynamic var dataTextView:         NSTextView?
    @objc @IBOutlet private dynamic var asciiTextView:        NSTextView?
    
    convenience init( url: URL )
    {
        self.init()
        
        self.url  = url
        self.file = ( url.path as NSString ).lastPathComponent
        self.icon = NSWorkspace.shared.icon( forFile: url.path )
    }
    
    override var windowNibName: NSNib.Name?
    {
        return NSNib.Name( NSStringFromClass( type( of: self ) ) )
    }
    
    override func windowDidLoad()
    {
        super.windowDidLoad()
        
        self.window?.titlebarAppearsTransparent    = true
        self.window?.titleVisibility               = .hidden
        self.window?.title                         = self.file ?? ""
        self.dictionaryController?.sortDescriptors = [ NSSortDescriptor( key: "key", ascending: true ) ]
        
        guard let url = self.url else
        {
            return
        }
        
        self.loading = true
        
        DispatchQueue.global( qos: .userInitiated ).async
        {
            let box = BoxItem( url: url )
            
            DispatchQueue.main.async
            {
                self.box     = box
                self.loading = false
                
                self.outlineView?.expandItem( self.outlineView?.item( atRow: 0 ) )
            }
        }
        
        for textView in [ self.dataTextView, self.asciiTextView ]
        {
            textView?.font               = NSFont.userFixedPitchFont( ofSize: 12 )
            textView?.textContainerInset = NSSize( width: 10, height: 10 )
        }
    }
    
    // MARK: NSTextFieldDelegate
    
    func controlTextDidChange( _ obj: Notification )
    {
        if( self.searchField?.stringValue.count == 0 )
        {
            self.box?.setPredicate( nil )
        }
        else
        {
            self.box?.setPredicate( NSPredicate( format: "index contains[c] %@", argumentArray: [ self.searchField?.stringValue as Any ] ) )
        }
    }
}
