//
//  UIViewController+MFSideMenu.m
//
//  Created by Michael Frederick on 3/18/12.
//

#import "UIViewController+MFSideMenu.h"
#import "MFSideMenuManager.h"
#import <objc/runtime.h>

@class SideMenuViewController;

@interface UIViewController (MFSideMenuPrivate)
- (void)MFToggleSideMenu:(BOOL)hidden;
@end

@implementation UIViewController (MFSideMenu)

static char menuStateKey;

- (void) MFToggleSideMenuPressed:(id)sender {
    if(self.navigationController.MFMenuState == MFSideMenuStateVisible) {
        [self.navigationController setMFMenuState:MFSideMenuStateHidden];
    } else {
        [self.navigationController setMFMenuState:MFSideMenuStateVisible];
    }
}

- (void) MFBackButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) MFSetupSideMenuBarButtonItem {
    if(self.navigationController.MFMenuState == MFSideMenuStateVisible ||
       [[self.navigationController.viewControllers objectAtIndex:0] isEqual:self]) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                                 initWithImage:[UIImage imageNamed:@"menu-icon.png"] style:UIBarButtonItemStyleBordered 
                                                 target:self action:@selector(MFToggleSideMenuPressed:)];
    } else {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back-arrow"]
                                         style:UIBarButtonItemStyleBordered target:self action:@selector(MFBackButtonPressed:)];
    }
}

- (void)setMFMenuState:(MFSideMenuState)menuState {
    if(![self isKindOfClass:[UINavigationController class]]) {
        self.navigationController.MFMenuState = menuState;
        return;
    }
    
    MFSideMenuState currentState = self.MFMenuState;
    
    objc_setAssociatedObject(self, &menuStateKey, [NSNumber numberWithInt:menuState], OBJC_ASSOCIATION_RETAIN);
    
    switch (currentState) {
        case MFSideMenuStateHidden:
            if (menuState == MFSideMenuStateVisible) {
                [self MFToggleSideMenu:NO];
            }
            break;
        case MFSideMenuStateVisible:
            if (menuState == MFSideMenuStateHidden) {
                [self MFToggleSideMenu:YES];
            }
            break;
        default:
            break;
    }
}

- (MFSideMenuState)MFMenuState {
    if(![self isKindOfClass:[UINavigationController class]]) {
        return self.navigationController.MFMenuState;
    }
    
    return (MFSideMenuState)[objc_getAssociatedObject(self, &menuStateKey) intValue];
}

- (void)MFSideMenuAnimationFinished:(NSString *)animationID finished:(BOOL)finished context:(void *)context
{
    if ([animationID isEqualToString:@"toggleSideMenu"])
    {
        if([self isKindOfClass:[UINavigationController class]]) {
            UINavigationController *controller = (UINavigationController *)self;
            [controller.visibleViewController MFSetupSideMenuBarButtonItem];
            
            // disable user interaction on the current view controller
            controller.visibleViewController.view.userInteractionEnabled = (self.MFMenuState == MFSideMenuStateHidden);
            [[MFSideMenuManager sharedManager] sideMenuController].view.userInteractionEnabled = (self.MFMenuState != MFSideMenuStateHidden);
        }
    }
}

@end


@implementation UIViewController (MFSideMenuPrivate)

// TODO: alter the duration based on the current position of the menu
// to provide a smoother animation
- (void) MFToggleSideMenu:(BOOL)hidden {
    if(![self isKindOfClass:[UINavigationController class]]) return;
    
    [UIView beginAnimations:@"toggleSideMenu" context:NULL];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(MFSideMenuAnimationFinished:finished:context:)];
    [UIView setAnimationDuration:kMenuAnimationDuration];
    
    CGRect frame = self.view.frame;
    frame.origin = CGPointZero;
    if (!hidden) {
        switch (self.interfaceOrientation) 
        {
            case UIInterfaceOrientationPortrait:
                frame.origin.x = kSidebarWidth;
                break;
                
            case UIInterfaceOrientationPortraitUpsideDown:
                frame.origin.x = -1*kSidebarWidth;
                break;
                
            case UIInterfaceOrientationLandscapeLeft:
                frame.origin.y = -1*kSidebarWidth;
                break;
                
            case UIInterfaceOrientationLandscapeRight:
                frame.origin.y = kSidebarWidth;
                break;
        } 
    }
    self.view.frame = frame;
        
    [UIView commitAnimations];
}

@end 
