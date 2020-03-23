//
//  ViewController.m
//  PlistView
//
//  Created by junhai on 2020/3/9.
//  Copyright © 2020 junhai. All rights reserved.
//

#import "ViewController.h"

#import "PropertyListItem.h"

@interface ViewController () <NSOutlineViewDataSource, NSOutlineViewDelegate, NSWindowDelegate>

@property (weak) IBOutlet NSScrollView *container;
@property (weak) IBOutlet NSOutlineView *outlineView;

@property (nonatomic, strong) PropertyListItem *rootItem;
@property (nonatomic, strong) MergedItem *mergedItem;

@property (nonatomic, copy) NSURL *plistURL;
@property (nonatomic, assign) NSPropertyListFormat plistFormat;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.container.hidden = YES;
    self.outlineView.dataSource = self;
    self.outlineView.delegate = self;
    [self.outlineView reloadData];
}

- (void)viewWillAppear {
    [super viewWillAppear];
    
    [self.view.window registerForDraggedTypes:[NSArray arrayWithObjects:NSPasteboardTypeFileURL, nil]];
    self.view.window.delegate = self;
    
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self.outlineView reloadData];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}

#pragma mark -

- (IBAction)clear:(id)sender {
    self.rootItem = nil;
    self.mergedItem = nil;
    self.plistFormat = 0;
    self.plistURL = nil;
    self.container.hidden = YES;
}

- (IBAction)undo:(id)sender {
    self.mergedItem = nil;
    [self.outlineView reloadData];
    [self.outlineView expandItem:[self outlineViewDataModel] expandChildren:YES];
}

- (IBAction)export:(id)sender {
    NSString *alertSuppressionKey = @"AlertSuppression";
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
     
    if ([defaults boolForKey: alertSuppressionKey]) {
        NSLog (@"Alert suppressed");
    } else {
        NSAlert *alert= [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"ok"];
        [alert addButtonWithTitle:@"cancel"];
        alert.messageText = @"结果将直接覆盖原Plist文件。在“清空”或关闭App前可用“还原Plist”还原。";
        alert.showsSuppressionButton = YES;
        [alert runModal];
        if (alert.suppressionButton.state == NSControlStateValueOn) {
            // Suppress this alert from now on
            [defaults setBool: YES forKey: alertSuppressionKey];
        }
    }
    
    
    if (self.mergedItem && self.plistURL) {
        NSOutputStream *stream = [[NSOutputStream alloc] initWithURL:self.plistURL append:NO];
        [stream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [stream open];
        NSError *e;
        NSInteger bytes = [NSPropertyListSerialization writePropertyList:self.mergedItem.value toStream:stream format:self.plistFormat options:0 error:&e];
        if (e) {
            NSLog(@"change plist error: %@", e);
        } else {
            NSLog(@"change plist succeeded:%ld", (long)bytes);
            NSAlert *alert= [[NSAlert alloc] init];
            alert.messageText = @"修改成功";
            [alert beginSheetModalForWindow:self.view.window completionHandler:nil];
        }
    }
}

- (IBAction)restore:(id)sender {
    if (self.rootItem && self.plistURL) {
        NSOutputStream *stream = [[NSOutputStream alloc] initWithURL:self.plistURL append:NO];
        [stream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [stream open];
        NSError *e;
        NSInteger bytes = [NSPropertyListSerialization writePropertyList:self.rootItem.value toStream:stream format:self.plistFormat options:0 error:&e];
        if (e) {
            NSLog(@"restore plist error: %@", e);
        } else {
            [self undo:nil];
            NSLog(@"restore plist succeeded:%ld", (long)bytes);
            NSAlert *alert= [[NSAlert alloc] init];
            alert.messageText = @"还原成功";
            [alert beginSheetModalForWindow:self.view.window completionHandler:nil];
        }
    }
}

#pragma mark -

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (item == nil) {
        return [self outlineViewDataModel] ? 1 : 0;
    } else {
        if ([item isKindOfClass:[PropertyListItem class]]) {
            if ([item isKindOfClass:[MergedItem class]]) {
                if ([[(MergedItem *)item originValue] isKindOfClass:[NSArray class]] && [[(MergedItem *)item value] isKindOfClass:[NSArray class]]) {
                    return [[(MergedItem *)item originValue] count] + [[(PropertyListItem *)item children] count];
                }
            }
            return [[(PropertyListItem *)item children] count];
        } else {
            return 0;
        }
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return [(PropertyListItem *)item expandable];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (item == nil) {
        return [self outlineViewDataModel];
    } else if ([item isKindOfClass:[PropertyListItem class]]) {
        if ([item isKindOfClass:[MergedItem class]]) {
            if ([[(MergedItem *)item originValue] isKindOfClass:[NSArray class]] && [[(MergedItem *)item value] isKindOfClass:[NSArray class]]) {
                if (index < [[(MergedItem *)item originValue] count]) {
                    return [[(MergedItem *)item originValue] objectAtIndex:index];
                } else {
                    return [[(MergedItem *)item children] objectAtIndex:index - [[(MergedItem *)item originValue] count]];
                }
            }
        }
        return [[(PropertyListItem *)item children] objectAtIndex:index];
    } else {
        return nil;
    }
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    if ([tableColumn.identifier isEqualToString:@"Key"]) {
        if ([(PropertyListItem *)item key].length == 0) {
            return [NSString stringWithFormat:@"item %lu", [outlineView childIndexForItem:item]];
        } else {
            return [(PropertyListItem *)item key];
        }
    } else if ([tableColumn.identifier isEqualToString:@"Type"]) {
        return [(PropertyListItem *)item type];
    } else if ([tableColumn.identifier isEqualToString:@"Value"]) {
        if ([(PropertyListItem *)item expandable]) {
            return [NSString stringWithFormat:@"(%lu items)", [(PropertyListItem *)item children].count];
        } else {
            if ([[(PropertyListItem *)item type] isEqualToString:@"Boolean"]) {
                return [[(PropertyListItem *)item value] boolValue] ? @"YES":@"NO";
            }
            return [NSString stringWithFormat:@"%@", [(PropertyListItem *)item value]];
        }
    } else {
        return nil;
    }
}


- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    NSTableCellView *result = [outlineView makeViewWithIdentifier:tableColumn.identifier owner:self];
    if ([item isKindOfClass:[MergedItem class]] && [(MergedItem *)item isDifferent]) {
        result.textField.textColor = [NSColor blueColor];
    } else {
        result.textField.textColor = [NSColor blackColor];
        
    }
    if ([tableColumn.identifier isEqualToString:@"Value"]) {
        if ([(PropertyListItem *)item expandable]) {
            result.textField.textColor = [NSColor lightGrayColor];
        }
    }
    result.textField.font = [NSFont systemFontOfSize:12 weight:NSFontWeightLight];
    return result;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(nonnull id)item {
    return NO;
}

#pragma mark -

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender{
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ([[pboard types] containsObject:NSPasteboardTypeFileURL]) {
        return NSDragOperationCopy;
    }
    return NSDragOperationNone;
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender{
    NSURL *url = [NSURL URLFromPasteboard:[sender draggingPasteboard]];
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSError *e;
    id propertylist = [NSPropertyListSerialization propertyListWithData:data options:(NSPropertyListMutableContainers) format:&_plistFormat error:&e];
    
    if (e) {
        NSLog(@"=======:%@", e);
        return NO;
    }
        
    if (self.rootItem) {
        self.mergedItem = [MergedItem itemWithOriginItem:self.rootItem mergeWithData:propertylist];
    } else {
        self.plistURL = url;
        self.rootItem = [PropertyListItem rootItemWithData:propertylist];
    }
    [self.outlineView reloadData];
    [self.outlineView expandItem:[self outlineViewDataModel] expandChildren:YES];
    [self.outlineView sizeLastColumnToFit];
    self.container.hidden = NO;
    return YES;
}

- (PropertyListItem *)outlineViewDataModel {
    if (self.mergedItem) {
        return self.mergedItem;
    } else {
        return self.rootItem;
    }
}

@end
