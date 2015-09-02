//
//  FontSizeTBVC.m
//  Kiwix
//
//  Created by Chris Li on 7/13/15.
//  Copyright (c) 2015 Chris Li. All rights reserved.
//

#import "FontSizeTBVC.h"
#import "JMMarkSlider.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface FontSizeTBVC ()

@property (weak, nonatomic) IBOutlet JMMarkSlider *slider;

- (IBAction)sliderValueChanged:(JMMarkSlider *)sender;
- (IBAction)sliderTouchUpInside:(JMMarkSlider *)sender;

@end

@implementation FontSizeTBVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Adjust Font Size";
    
    self.slider.markColor = [UIColor colorWithWhite:1 alpha:0.5];
    self.slider.markPositions = @[@0,@16.67,@33.33,@50,@66.67,@83.33,@100];
    self.slider.markWidth = 1.0;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"webViewScalePageToFitWidth"]) {
        self.slider.selectedBarColor = [UIColor grayColor];
        self.slider.unselectedBarColor = [UIColor darkGrayColor];
        self.slider.userInteractionEnabled = NO;
    } else {
        self.slider.selectedBarColor = UIColorFromRGB(0xFF9933);
        self.slider.unselectedBarColor = UIColorFromRGB(0xFF6600);
        self.slider.userInteractionEnabled = YES;
    }
    
    NSUInteger value = [[NSUserDefaults standardUserDefaults] integerForKey:@"webViewZoomScale"] == 0 ? 100 : [[NSUserDefaults standardUserDefaults] integerForKey:@"webViewZoomScale"];
    self.slider.value = (value - 85) / 5.0;
    self.tableView.tableFooterView = [self tableFooterViewWithWidth:self.tableView.frame.size.width];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    NSUInteger value = 85 + lroundf(self.slider.value) * 5.0;
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:@"webViewZoomScale"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    self.tableView.tableFooterView = [self tableFooterViewWithWidth:size.width];
}

- (UIView *)tableFooterViewWithWidth:(CGFloat)width {
    NSString *message = @"Drag the slider above to adjust the font size of the article. The size of the percentage numbers shows the acutal font size of article body on screen. \n\nFont size adjustment is applied only when Scale Page to Fit Width is off in settings.";
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        width = self.navigationController.preferredContentSize.width;
    }
    
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    CGFloat inset = 20;
    CGSize estimatedSize = CGSizeMake(width - 2*inset, 2000);
    CGRect labelRect = [message boundingRectWithSize:estimatedSize options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: font} context:nil];
    UILabel *footerLabel = [[UILabel alloc] initWithFrame:CGRectMake((width-labelRect.size.width)/2, 0, labelRect.size.width, labelRect.size.height)];
    footerLabel.text = message;
    footerLabel.textColor = [UIColor darkGrayColor];
    footerLabel.opaque = NO;
    footerLabel.numberOfLines = 0;
    footerLabel.font = font;
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, labelRect.size.height)];
    [footerView addSubview:footerLabel];
    return footerView;
}

- (IBAction)sliderValueChanged:(UISlider *)sender {
    
}

- (IBAction)sliderTouchUpInside:(UISlider *)sender {
    NSUInteger sliderValue = lroundf(sender.value);
    [sender setValue:sliderValue animated:YES];
}
@end
