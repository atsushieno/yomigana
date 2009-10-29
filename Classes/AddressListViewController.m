//
//  AddressListViewController.m
//  Yomigana
//
//  Created by Atsushi Eno on 09/03/12.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AddressListViewController.h"

@implementation AddressListViewController
{
}

@synthesize addressbook;
@synthesize people;

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

	addressbook = ABAddressBookCreate ();
	people = (NSMutableArray*) ABAddressBookCopyArrayOfAllPeople (addressbook);
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
    [super dealloc];
}

NSString* escapeString (NSString* lastName, NSString* firstName)
{
	NSString *eLast = [lastName stringByReplacingOccurrencesOfString:@" " withString:@"##1##"];
	NSString *eFirst = [firstName stringByReplacingOccurrencesOfString:@" " withString:@"##1##"];
	return [@"" stringByAppendingFormat:@"""%@ %@""", eLast, eFirst];
}

- (void) callYomiganaService {
	NSString *names[[people count]];
	for (int i = 0; i < [people count]; i++) {
		ABRecordRef *person = (ABRecordRef*) [people objectAtIndex:i];
		NSString* firstName = (NSString*) ABRecordCopyValue (person, kABPersonFirstNameProperty);
		NSString* lastName = (NSString*) ABRecordCopyValue (person, kABPersonLastNameProperty);
		names [i] = [escapeString (lastName, firstName)
					 stringByReplacingOccurrencesOfString:@"\"" withString:@"##3##"];
	}
	NSString *input = @"[";
	for (int i = 0; i < [people count]; i++) {
		if (i > 0)
			input = [input stringByAppendingString:@","];
		input = [input stringByAppendingString:names[i]];
	}
	input = [input stringByAppendingString:@"]"];
	NSLog(input);
	NSString *reply = [AddressListViewController getYomigana:input];
	NSRange range = [reply rangeOfString:@"["];
	if (range.location == NSNotFound) {
		[self notifyFailure: @"サーバが予期しない応答を返しました。(ERROR CODE 101)"];
		return;
	}
	int start = range.location;
	range = [reply rangeOfString:@"]" options: NSBackwardsSearch];
	if (range.location == NSNotFound) {
		[self notifyFailure: @"サーバが予期しない応答を返しました。(ERROR CODE 102)"];
		return;
	}
	int end = range.location;
	reply = [reply substringWithRange:NSMakeRange (start + 1, end - start - 1)];
	NSArray *replyNames = [reply componentsSeparatedByString:@","];
	NSLog([NSString stringWithFormat: @"%d", [replyNames count]]);
	for (int i = 0; i < [people count]; i++) {
		NSLog ([@"> " stringByAppendingString: (NSString*) [replyNames objectAtIndex:i]]);
		ABRecordRef *person = (ABRecordRef*) [people objectAtIndex:i];
		NSString* firstYomi = (NSString*) ABRecordCopyValue (person, kABPersonFirstNamePhoneticProperty);
		NSString* lastYomi = (NSString*) ABRecordCopyValue (person, kABPersonLastNamePhoneticProperty);
		if (firstYomi && lastYomi)
			continue;
		NSArray *pair = [(NSString*) [replyNames objectAtIndex:i] componentsSeparatedByString:@" "];
		NSString *inferredYomiFirst = (NSString*) [pair objectAtIndex:1];
		NSString *inferredYomiLast = (NSString*) [pair objectAtIndex:0];
		NSLog (inferredYomiLast);
		NSLog (inferredYomiFirst);
		ABRecordSetValue (person, kABPersonLastNamePhoneticProperty, inferredYomiLast, nil);
		ABRecordSetValue (person, kABPersonFirstNamePhoneticProperty, inferredYomiFirst, nil);
	}
	ABAddressBookSave(addressbook, nil);
}

- (void) notifyFailure: (NSString*) message {
	UIAlertView *alert = [UIAlertView alloc];
	alert.message = message;
	[alert show];
	[alert release];
}

+ (NSString*) getYomigana:(NSString*) source {
	NSString *utf8url = [@"http://veritas-vos-liberabit.com/yomigana/yomigana.cgi?source=" stringByAppendingString: source];
	NSString *escapedUrl = [utf8url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSURL *urlobj = [NSURL URLWithString:escapedUrl];
	NSError *err;
	NSString* result = [NSString stringWithContentsOfURL:urlobj encoding:NSUTF8StringEncoding error:&err];
	return result;
}

- (NSString*) getFormattedYomigana:(ABRecordRef) person {
	NSString* firstYomi = (NSString*) ABRecordCopyValue (person, kABPersonFirstNamePhoneticProperty);
	NSString* lastYomi = (NSString*) ABRecordCopyValue (person, kABPersonLastNamePhoneticProperty);
	if (lastYomi)
		return [lastYomi stringByAppendingFormat:@" %@", firstYomi];
	else
		return firstYomi;
}

- (NSString*) formatPerson:(ABRecordRef) person {
	NSString* firstName = (NSString*) ABRecordCopyValue(person, kABPersonFirstNameProperty);
	NSString* lastName = (NSString*) ABRecordCopyValue(person, kABPersonLastNameProperty);
	NSString* firstYomi = (NSString*) ABRecordCopyValue (person, kABPersonFirstNamePhoneticProperty);
	NSString* lastYomi = (NSString*) ABRecordCopyValue (person, kABPersonLastNamePhoneticProperty);

	if (lastYomi || firstYomi)
		return [@"" stringByAppendingFormat:@"%@ %@ (%@ %@)",lastName, firstName, lastYomi, firstYomi];
	else
		return [@"" stringByAppendingFormat:@"%@ %@", lastName, firstName];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [(NSMutableArray*)people count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellVisibleIdentifier = @"CellVisible";
    static NSString *CellInvisibleIdentifier = @"CellInvisible";
    NSString *ident = CellVisibleIdentifier;
	if ([self getFormattedYomigana:(ABRecordRef) [people objectAtIndex:indexPath.row]])
		ident = CellInvisibleIdentifier;
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ident];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:ident] autorelease];
    }
    
    // Set up the cell...
	cell.text = [self formatPerson:(ABRecordRef) [people objectAtIndex:indexPath.row]];
	if (ident == CellInvisibleIdentifier)
		cell.textColor = [UIColor lightGrayColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
}


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */


/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }   
 }
 */


/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */


/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */


@end
