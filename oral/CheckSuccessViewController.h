//
//  CheckSuccessViewController.h
//  oral
//
//  Created by cocim01 on 15/5/20.
//  Copyright (c) 2015年 keximeng. All rights reserved.
//

#import "TopicParentsViewController.h"
/*
    闯关成功 or 失败 过渡页
 */
@interface CheckSuccessViewController : TopicParentsViewController

@property (weak, nonatomic) IBOutlet UIButton *backButton;
- (IBAction)backToLastPage:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *continueButton;
- (IBAction)continueNextPoint:(id)sender;

@property (nonatomic,assign) NSInteger pointCount;


@end
