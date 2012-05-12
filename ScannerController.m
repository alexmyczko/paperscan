/* 
 * Project: PaperScan
 *
 * Author: Philippe Roussel <p.o.roussel@free.fr>
 *
 * Created: 2012-05-10 23:40:08 +0200 by philou
 *  
 */

#import <Foundation/Foundation.h>
#import "ScannerController.h"

@implementation Scanner
- (id)initWithSANEDevice:(SANE_Device *)device
{
  if ((self = [super init])) {
    name = [[NSString alloc] initWithCString:device->name];
    vendor = [[NSString alloc] initWithCString:device->vendor];
    model = [[NSString alloc] initWithCString:device->model];
    type = [[NSString alloc] initWithCString:device->type];
  }
  return self;
}

- (void)dealloc
{
  RELEASE(name);
  RELEASE(vendor);
  RELEASE(model);
  RELEASE(type);
  [super dealloc];
}

- (NSString *)description
{
  return model;
}
- (NSString *)name
{
  return name;
}
- (NSString *)vendor
{
  return vendor;
}
- (NSString *)model
{
  return model;
}
- (NSString *)type
{
  return type;
}
@end

NSString * const PSDeviceListUpdated = @"PSDeviceListUpdated";

static NSLock *devarrayLock;
static NSMutableArray *devarray;

@implementation ScannerController
- (id)init
{
  SANE_Int version;
  SANE_Status status;

  if ((self = [super init])) {
    status = sane_init(&version, NULL);
    if (status != SANE_STATUS_GOOD) {
      NSLog(@"Unable to initialize sane : %s", sane_strstatus(status));
      DESTROY(self);
      return nil;
    }
    devarrayLock = [NSLock new];
    devarray = [NSMutableArray new];
    [self availableScanner];
  }
  return self;
}

- (void)dealloc
{
  sane_exit();
  [devarray release];
  [devarrayLock release];
  [super dealloc];
}

- (void)_notifyListBuilt:(id)argument
{
  [[NSNotificationCenter defaultCenter] postNotificationName:PSDeviceListUpdated
						      object:nil];
}

- (void)_buildDeviceList:(id)argument
{
  SANE_Status status;
  const SANE_Device **devices;
  Scanner *scan;
  
  status = sane_get_devices(&devices, SANE_TRUE);
  if (status != SANE_STATUS_GOOD) {
    NSLog(@"Error while getting list of devices : %s", sane_strstatus(status));
    return;
  }
  [devarrayLock lock];
  [devarray removeAllObjects];
  while (*devices) {
    scan = [[Scanner alloc] initWithSANEDevice:(SANE_Device *)*devices];
    [devarray addObject:scan];
    [scan release];
    devices++;
  }
  [devarrayLock unlock];
  NSLog(@"Found %u device(s)", [devarray count]);
  [self performSelectorOnMainThread:@selector(_notifyListBuilt:) 
			 withObject:nil 
		      waitUntilDone:NO];
}

- (void)buildDeviceList
{
  [NSThread detachNewThreadSelector:@selector(_buildDeviceList:) 
			   toTarget:self 
			 withObject:nil];
}

- (NSArray *)availableScanner
{
  NSArray *array;

  [devarrayLock lock];
  array = [NSArray arrayWithArray:devarray];
  [devarrayLock unlock];
  return array;
}

- (void)scanPage
{
}

@end
