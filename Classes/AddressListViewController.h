//
//  AddressListViewController.h
//  Yomigana
//
//  Created by Atsushi Eno on 09/03/12.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>

@interface AddressListViewController : UIViewController {
	ABAddressBookRef addressbook;
	NSMutableArray *people;
}

@property (nonatomic) IBOutlet ABAddressBookRef addressbook;
@property (nonatomic, retain) IBOutlet NSMutableArray *people;

+ (NSString*) getYomigana: (NSString*) source;
- (NSString*) getFormattedYomigana: (ABRecordRef) person;
- (NSString*) formatPerson: (ABRecordRef) person;

- (NSInteger) tableView: (UITableView*) tableView numberOfRowsInSection: (NSInteger) section;
- (UITableViewCell*) tableView: (UITableView*) tableView cellForRowAtIndexPath: (NSIndexPath*) indexPath;

- (void) callYomiganaService;
- (void) notifyFailure: (NSString*) message;

@end
