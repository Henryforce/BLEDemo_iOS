//
//  DetailViewController.h
//  BLEDemo
//
//  Created by Henry Serrano on 3/11/15.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end

