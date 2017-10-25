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

#import "BoxItem.h"
#import <ISOBMFF.hpp>

NS_ASSUME_NONNULL_BEGIN

@interface BoxItem()

@property( atomic, readwrite, assign           ) BOOL                                            isLeaf;
@property( atomic, readwrite, weak             ) BoxItem                                       * parent;
@property( atomic, readwrite, strong           ) NSString                                      * name;
@property( atomic, readwrite, strong           ) NSString                                      * index;
@property( atomic, readwrite, strong           ) NSImage                                       * icon;
@property( atomic, readwrite, strong           ) NSArray< BoxItem * >                          * children;
@property( atomic, readwrite, strong           ) NSMutableArray< BoxItem * >                   * allChildren;
@property( atomic, readwrite, strong           ) NSMutableDictionary< NSString *, NSString * > * mutableProperties;
@property( atomic, readwrite, strong, nullable ) NSString                                      * data;
@property( atomic, readwrite, strong, nullable ) NSString                                      * asciiData;

- ( instancetype )initWithObject: ( std::shared_ptr< ISOBMFF::DisplayableObject > )box parent: ( nullable BoxItem * )parent NS_DESIGNATED_INITIALIZER;
- ( NSString * )buildIndex;
- ( void )setDataBytes: ( const std::vector< uint8_t > & )bytes;

@end

NS_ASSUME_NONNULL_END

@implementation BoxItem

- ( instancetype )init
{
    return [ self initWithObject: nullptr parent: nil ];
}

- ( instancetype )initWithURL: ( nullable NSURL * )url
{
    ISOBMFF::Parser parser;
    
    try
    {
        parser.AddOption( ISOBMFF::Parser::Options::SkipMDATData );
        parser.Parse( url.path.UTF8String );
    }
    catch( ... )
    {}
    
    if( ( self = [ self initWithObject: parser.GetFile() parent: nil ] ) )
    {
        if( url.path.lastPathComponent.length > 0 )
        {
            self.name = url.path.lastPathComponent;
            self.icon = [ [ NSWorkspace sharedWorkspace ] iconForFile: url.path ];
        }
    }
    
    return self;
}

- ( instancetype )initWithObject: ( std::shared_ptr< ISOBMFF::DisplayableObject > )object parent: ( nullable BoxItem * )parent
{
    if( ( self = [ super init ] ) )
    {
        self.isLeaf            = YES;
        self.allChildren       = [ NSMutableArray new ];
        self.mutableProperties = [ NSMutableDictionary new ];
        self.icon              = [ [ NSWorkspace sharedWorkspace ] iconForFileType: @"pkg" ];
        self.parent            = parent;
        
        if( object == nullptr )
        {
            self.name = @"";
        }
        else
        {
            self.name = [ NSString stringWithUTF8String: object->GetName().c_str() ];
            
            if( std::dynamic_pointer_cast< ISOBMFF::Container >( object ) != nullptr )
            {
                self.isLeaf = NO;
                
                if( std::dynamic_pointer_cast< ISOBMFF::ContainerBox >( object ) != nullptr )
                {
                    self.icon = [ NSImage imageNamed: NSImageNameFolder ];
                }
                
                for( const auto & sub: std::dynamic_pointer_cast< ISOBMFF::Container >( object )->GetBoxes() )
                {
                    [ self.allChildren addObject: [ [ BoxItem alloc ] initWithObject: sub parent: self ] ];
                }
            }
            
            if( std::dynamic_pointer_cast< ISOBMFF::DisplayableObjectContainer >( object ) != nullptr )
            {
                self.isLeaf = NO;
                
                for( const auto & sub: std::dynamic_pointer_cast< ISOBMFF::DisplayableObjectContainer >( object )->GetDisplayableObjects() )
                {
                    [ self.allChildren addObject: [ [ BoxItem alloc ] initWithObject: sub parent: self ] ];
                }
            }
            
            if( std::dynamic_pointer_cast< ISOBMFF::Box >( object ) != nullptr )
            {
                [ self setDataBytes: std::dynamic_pointer_cast< ISOBMFF::Box >( object )->GetData() ];
            }
            
            for( const auto & p: object->GetDisplayableProperties() )
            {
                {
                    NSString * k;
                    NSString * v;
                    
                    k = [ NSString stringWithUTF8String: p.first.c_str() ];
                    v = [ NSString stringWithUTF8String: p.second.c_str() ];
                    
                    [ self.mutableProperties setObject: v forKey: k ];
                }
            }
            
            self.children = self.allChildren.copy;
            self.index    = [ self buildIndex ];
        }
    }
    
    return self;
}

- ( NSDictionary< NSString *, NSString * > * )properties
{
    return self.mutableProperties.copy;
}

- ( void )setPredicate: ( nullable NSPredicate * )predicate
{
    BoxItem * child;
    
    for( child in self.allChildren )
    {
        [ child setPredicate: predicate ];
    }
    
    if( predicate == nil )
    {
        self.children = self.allChildren.copy;
    }
    else
    {
        self.children = [ self.allChildren filteredArrayUsingPredicate: ( NSPredicate * )predicate ];
    }
}

- ( NSString * )buildIndex
{
    NSMutableString * index;
    BoxItem         * child;
    BoxItem         * parent;
    NSDictionary    * props;
    NSString        * k;
    
    index = self.name.mutableCopy;
    
    for( child in self.allChildren )
    {
        [ index appendFormat: @" %@", child.index ];
    }
    
    props = self.properties;
    
    for( k in props )
    {
        [ index appendFormat: @" %@ %@", k, [ props objectForKey: k ] ];
    }
    
    parent = self.parent;
    
    while( parent != nil )
    {
        [ index appendFormat: @" %@", parent.name ];
        
        parent = parent.parent;
    }
    
    return index.copy;
}

- ( void )setDataBytes: ( const std::vector< uint8_t > & )bytes
{
    NSMutableString * data;
    NSMutableString * ascii;
    
    if( bytes.size() == 0 )
    {
        return;
    }
    
    data  = [ NSMutableString new ];
    ascii = [ NSMutableString new ];
    
    for( const auto & b: bytes )
    {
        [ data  appendFormat: @"%02X ", b ];
        [ ascii appendFormat: @"%c", ( isprint( b ) && !isspace( b ) ) ? b : '.' ];
    }
    
    [ data deleteCharactersInRange: NSMakeRange( data.length - 1, 1 ) ];
    
    self.data      = data.copy;
    self.asciiData = ascii.copy;
}

@end
