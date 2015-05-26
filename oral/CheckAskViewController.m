//
//  CheckAskViewController.m
//  oral
//
//  Created by cocim01 on 15/5/20.
//  Copyright (c) 2015年 keximeng. All rights reserved.
//

#import "CheckAskViewController.h"
#import "AudioPlayer.h"
#import "RecordManager.h"
#import "CircleProgressView.h"
#import "MyTeacherViewController.h"
#import "TPCCheckpointViewController.h"

@interface CheckAskViewController ()
{
    NSDictionary *_topicInfoDict;// 整个topic信息
    NSDictionary *_currentPartDict;// 当前part资源信息
    NSDictionary *_currentPointDict;// 当前关卡资源信息
    NSArray *_questioListArray;
    NSInteger _sumQuestionCounts;//总的问题个数
    NSInteger _currentQuestionCounts;
   
    AudioPlayer *audioPlayer;
    RecordManager *_recordManager;
    
    NSInteger _answerTime;//跟读时间
    NSTimer *_reduceTimer;
    
    CGRect _stuHeadImgViewRect;// 放大后学生头像的frame
    CGRect _stuHeadImgViewRect_small;// 缩小的学生头像的frame
    
    CircleProgressView *_progressView;
    
    NSInteger _markTimeChangeCounts;
    
    BOOL _pointFinished;

//    CGRect _questionNomalRect;
//    CGRect _questionSmallRect;
}
@end

@implementation CheckAskViewController
#define kTopQueCountButtonTag 333
#define kCommitLeftButtonTag 444
#define kCommitRightButtonTag 555

- (void)backToPrePage
{
    for (UIViewController *viewControllers in self.navigationController.viewControllers)
    {
        if ([viewControllers isKindOfClass:[TPCCheckpointViewController class]])
        {
            [self.navigationController popToViewController:viewControllers animated:YES];
            break;
        }
    }
}


#pragma mark - 模拟数据
- (void)moNiDataFromLocal
{
    /*
     数据结构
     
     _topicInfoDict--> topic闯关信息---> dict(字典)
     当前topic所有part--> partListArray = [_topicInfoDict objectForKey:@"partlist"] -->数组
     当前part--> curretPartDict = [partListArray objectAtIndex:_currentPartCounts] -->字典
     当前part的所有关卡信息 -- > pointArray = [curretPart objectForKey:@"levellist"] --> 数组
     当前关卡信息 pointDict = [pointArray objectAtIndex:_currentPointCounts] --> 字典
     pointDict
     
     ----待完善-----
     
     */
    NSString *jsonPath = [NSHomeDirectory() stringByAppendingFormat:@"/Documents/%@/topicResource/temp/info.json",self.topicName];
    NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    // 整个topic资源信息
    _topicInfoDict = [dict objectForKey:@"classtypeinfo"];
    // 当前part资源信息
    _currentPartDict = [[_topicInfoDict objectForKey:@"partlist"] objectAtIndex:self.currentPartCounts];
    // 当前关卡信息
    _currentPointDict = [[_currentPartDict objectForKey:@"levellist"] objectAtIndex:_currentPointCounts];
    // 当前关卡所有问题
    _questioListArray = [_currentPointDict objectForKey:@"questionlist"];
    // 总问题数
    _sumQuestionCounts = _questioListArray.count;
    // 当前进行的问题 起始：0
    _currentQuestionCounts = 0;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    _answerTime = 15;
    _markTimeChangeCounts = 0;
    _pointFinished = NO;

    _currentPointCounts = 0;

    
    audioPlayer = [AudioPlayer getAudioManager];
    audioPlayer.target = self;
    audioPlayer.action = @selector(playerCallBack);
    
    [self addBackButtonWithImageName:@"back-white"];
    [self addTitleLabelWithTitleWithTitle:@"Part1-3"];
    self.navTopView.backgroundColor = [UIColor colorWithRed:144/255.0 green:231/255.0 blue:208/255.0 alpha:1];
    self.titleLab.textColor = [UIColor whiteColor];
    [self moNiDataFromLocal];
    [self uiConfig];
    
    _recordManager = [[RecordManager alloc]init];
    _recordManager.target = self;
    _recordManager.action = @selector(recordFinished:);
    _recordManager.filePath = [NSHomeDirectory() stringByAppendingString:@"/Documents"];
}

- (void)uiConfig
{
    self.view.backgroundColor = [UIColor colorWithRed:245/255.0 green:249/255.0 blue:250/255.0 alpha:1];
    _topView.backgroundColor = [UIColor clearColor];
    _teacherView.backgroundColor = [UIColor clearColor];
    _stuView.backgroundColor = [UIColor clearColor];
    _bottomView.backgroundColor = [UIColor clearColor];
    
    // 背景颜色 去掉
    // 计算出按钮高度  不同尺寸屏幕 高度不同
    NSInteger btnWid = _topView.frame.size.height-2*8;
    // 根据总问题数创建按钮
    for (int i = 0; i < _sumQuestionCounts; i ++)
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setFrame:CGRectMake(20+i*(btnWid+10), 8, btnWid, btnWid)];
        [btn setTitle:[NSString stringWithFormat:@"%d",i+1] forState:UIControlStateNormal];
        [btn setBackgroundImage:[UIImage imageNamed:@"questionCount-white"] forState:UIControlStateNormal];
        // 选中
        [btn setBackgroundImage:[UIImage imageNamed:@"questionCount-blue"] forState:UIControlStateSelected];
        [btn setTitleColor:_backColor forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        btn.titleLabel.font = [UIFont systemFontOfSize:KThidFontSize];
        btn.tag = kTopQueCountButtonTag+i;
        if (i == 0)
        {
            btn.selected = YES;// 默认：1
        }
        [_topView addSubview:btn];
    }
    

    
    // 获取到老师背景View的frame
    CGRect rect = _teacherView.frame;
    float ratio = rect.size.width/rect.size.height;
    rect.size.width = kScreentWidth;
    rect.size.height = kScreentWidth/ratio;
    _teacherView.frame = rect;
    
    // 老师头像 圆形 有光圈
    _teaHeadImgView.image = [UIImage imageNamed:@"touxiang.png"];
    _teaHeadImgView.layer.masksToBounds = YES;
    _teaHeadImgView.layer.cornerRadius = (rect.size.height-20)/2;
    _teaHeadImgView.layer.borderColor = _backColor.CGColor;
    _teaHeadImgView.layer.borderWidth = 3;
    
    // 确定问题背景frame
    NSInteger queBackHH = _teaHeadImgView.frame.size.width;
    NSInteger queBackX = 30 + queBackHH;
    NSInteger queBackWW = kScreentWidth - queBackX - 20;
    _teaQuestioBackV.frame = CGRectMake(queBackX, 10, queBackWW, queBackHH);
    _teaQuestioBackV.layer.masksToBounds = YES;
    _teaQuestioBackV.backgroundColor = [UIColor whiteColor];
    _teaQuestioBackV.layer.cornerRadius = _teaQuestioBackV.frame.size.height/1334*kScreenHeight;
    
    // 问题文本 其实为空
    _teaQuestionLabel.numberOfLines = 0;
    _teaQuestionLabel.textColor = _textColor;
    _teaQuestionLabel.textAlignment = NSTextAlignmentCenter;
    _teaQuestionLabel.text = @"";
    /*
    _questionNomalRect = _teaQuestioBackV.bounds;
    _questionNomalRect.size.height -= 10;
    _questionNomalRect.size.width -= 10;
    _questionNomalRect.origin.x = 5;
    _questionNomalRect.origin.y = 5;
    
    _questionSmallRect = _questionNomalRect;
    _questionSmallRect.size.width = 0;
    
    _teaQuestionLabel.frame = _questionSmallRect;
    */
    
    float middleHeight = kScreenHeight-90-_teacherView.frame.size.height-(_bottomView.frame.size.height/_bottomView.frame.size.width*kScreentWidth);
    CGRect stuBackRect = _stuView.bounds;
    stuBackRect.size.height = middleHeight;
    stuBackRect.size.width = kScreentWidth;
    _stuView.frame = stuBackRect;
    
    // 确定学生头像frame  缩小frame 放大frame
    // 缩小的的头像
    _stuHeadImgV.center = _stuView.center;
    _stuHeadImgViewRect_small = _stuHeadImgV.frame;
    _stuHeadImgViewRect_small.origin.x = (kScreentWidth-_stuHeadImgV.frame.size.width)/2;
    _stuHeadImgViewRect_small.origin.y = (_stuView.frame.size.height-_stuHeadImgV.frame.size.width)/2;
    // 放大后的头像
    _stuHeadImgViewRect = _stuHeadImgViewRect_small;
    _stuHeadImgViewRect.origin.x -= 15;
    _stuHeadImgViewRect.origin.y -= 15;
    _stuHeadImgViewRect.size.width += 30;
    _stuHeadImgViewRect.size.height += 30;
    
    /*
         创建时间进度条： 圆形时间进度条 围绕在学生头像外圈
                       随着时间的增加而增加 当走完一圈 时间用尽 回答结束
     */
    
    [self createTimeProgress];
    
    // 提交按钮
    _CommitLeftButton.tag = kCommitLeftButtonTag;
    _commitRightButton.tag = kCommitRightButtonTag;
    
    [_followAnswerButton setBackgroundImage:[UIImage imageNamed:@"answerButton-sele"] forState:UIControlStateNormal];
    [_followAnswerButton setBackgroundImage:[UIImage imageNamed:@"answerButton-sele"] forState:UIControlStateSelected];
    
    /*
     初始状态:
                1> 问题文本不显示
                2> 老师、学生头像：暗 学生头像：小
                3> 跟读按钮：隐藏
     */
    
    _stuHeadImgV.alpha = 0.3;
    _teaHeadImgView.alpha = 0.3;
    _followAnswerButton.hidden = YES;
    [self narrowStuHeadImage];
}

#pragma mark - 创建时间进度条
- (void)createTimeProgress
{
    CGRect timeRect = _stuHeadImgViewRect;
    timeRect.origin.x -= 20;
    timeRect.origin.y -= 20;
    timeRect.size.width += 40;
    timeRect.size.height += 40;
    _progressView = [[CircleProgressView alloc]initWithFrame:timeRect];
    _progressView.backgroundColor = [UIColor clearColor];
    [_progressView settingProgress:0.0 andColor:_timeProgressColor andWidth:3 andCircleLocationWidth:3];
    [_stuView addSubview:_progressView];
    
    _progressView.hidden = YES;
    _progressView.center = _stuView.center;
}

#pragma mark - 时间进度变化
- (void)progressTimeReduce
{
    _markTimeChangeCounts ++;
    float tip = 1.0/_answerTime/10.0*_markTimeChangeCounts;
    [_progressView settingProgress:tip andColor:_timeProgressColor andWidth:3 andCircleLocationWidth:3];
    if (tip >= 1)
    {
        [self followAnswer:_followAnswerButton];
    }
}

#pragma mark - 放大学生的头像
- (void)enlargementStuHeadImage
{
    _stuHeadImgV.frame = _stuHeadImgViewRect;
    _stuHeadImgV.layer.cornerRadius = _stuHeadImgViewRect.size.width/2;
}

#pragma mark - 缩小学生的头像
- (void)narrowStuHeadImage
{
    _progressView.hidden = YES;
    [_progressView settingProgress:0 andColor:_timeProgressColor andWidth:3 andCircleLocationWidth:3];
    _stuHeadImgV.frame = _stuHeadImgViewRect_small;
    _stuHeadImgV.layer.cornerRadius = _stuHeadImgViewRect_small.size.width/2;
}

#pragma mark - 切换问题变换文本
- (void)showCurrentQuestionText
{
    _teaQuestionLabel.font = [UIFont systemFontOfSize:KOneFontSize];
    _teaQuestionLabel.text = [[_questioListArray objectAtIndex:_currentQuestionCounts] objectForKey:@"question"];
//    _teaQuestionLabel.frame = _questionNomalRect;
}

#pragma mark - 视图已经出现
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    /*
         停顿3秒 给学生准备时间 然后开始：
                                    1）问题文本出现 (要有动画效果)
                                    2）老实头像变亮
                                    3）播放问题音频
     */
    // 停顿3秒 开始point3流程
    if (!_pointFinished)// 此处加条件判断：如果是从其他界面返回则不走流程
    {
        _reduceTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(prepareQuestion) userInfo:nil repeats:NO];
    }
}

#pragma mark - 准备提问
- (void)prepareQuestion
{
    // 停掉定时器
    [self stopTimer];
    
    // 1) 文字出现动画
    [self questionAnimation];
    // 2）头像--> 亮
    [UIView animateWithDuration:1 animations:^{
        _teaHeadImgView.alpha = 1;
        _stuHeadImgV.alpha = 0.3;
    }];
    // 3）播放音频
    _reduceTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(playQuestion) userInfo:nil repeats:NO];
}

#pragma mark - 文字动画
- (void)questionAnimation
{
    [UIView beginAnimations:@"animationID" context:nil];
    [UIView setAnimationDuration:1.0f];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationRepeatAutoreverses:NO];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:_teaQuestionLabel cache:YES];
    [self showCurrentQuestionText];
    [self.view exchangeSubviewAtIndex:1 withSubviewAtIndex:0];
    [UIView commitAnimations];
}



#pragma mark -- 播放问题音频
- (void)playQuestion
{
    // 获取音频路径
    NSString *audiourl = [[_questioListArray objectAtIndex:_currentQuestionCounts] objectForKey:@"audiourl"];
    NSArray *audioArr = [audiourl componentsSeparatedByString:@"."];
    NSString *audioPath = [[NSBundle mainBundle]pathForResource:[audioArr objectAtIndex:0] ofType:[audioArr lastObject]];
    [audioPlayer playerPlayWithFilePath:audioPath];
}

#pragma MARK -- 播放完成 回调
- (void)playerCallBack
{
     // 播放完成 开始录音 保存本地
    [self prepareAnswer];
}

#pragma mark - 准备回答
- (void)prepareAnswer
{
    [UIView animateWithDuration:2 animations:^{
        [self enlargementStuHeadImage];
        _stuHeadImgV.alpha = 1;
        _teaHeadImgView.alpha = 0.3;
    }];
    _reduceTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(showFollowButton) userInfo:nil repeats:NO];
}

- (void)showFollowButton
{
    [self stopTimer];
    _followAnswerButton.hidden = NO;
    [self followAnswer:_followAnswerButton];
}

#pragma mark - 停止定时器
- (void)stopTimer
{
    [_reduceTimer invalidate];
    _reduceTimer = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)followAnswer:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    if (btn.selected)
    {
        btn.selected = NO;
       // 结束回答
        btn.hidden = YES;
        [_recordManager stopRecord];
        [self stopTimer];
    }
    else
    {
        btn.selected = YES;
        // 开始录音
//        [self startRecord];
        [_recordManager prepareRecorderWithFileName:@"answer1"];
        [self showTimeProgress];
        
    }
}

- (void)showTimeProgress
{
    _progressView.hidden = NO;
    _reduceTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(progressTimeReduce) userInfo:nil repeats:YES];
}

#pragma mark - 开始录音
- (void)startRecord
{
    // 后续完善（根据数据）
   [_recordManager prepareRecorderWithFileName:@"answer1"];
}

#pragma mark - 录音结束回调
- (void)recordFinished:(RecordManager *)manager
{
    [self nextQuestion];
}

#pragma mark - 进行下一题
- (void)nextQuestion
{
    _currentQuestionCounts++;
    _markTimeChangeCounts = 0;
    if (_currentQuestionCounts<_sumQuestionCounts)
    {
        // 继续
        [UIView animateWithDuration:2 animations:^{
            [self narrowStuHeadImage];
            _stuHeadImgV.alpha = 0.3;
        }];
        _reduceTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(prepareQuestion) userInfo:nil repeats:NO];
    }
    else
    {
       // 提交给老师
        _CommitLeftButton.hidden = NO;
        _commitRightButton.hidden = NO;
    }
}

#pragma mark - 提交按钮
- (IBAction)commitButtonClicked:(id)sender
{
    _pointFinished = YES;
    UIButton *btn = (UIButton *)sender;
    if (btn.tag == kCommitLeftButtonTag)
    {
        // 稍后提交
    }
    else if (btn.tag == kCommitRightButtonTag)
    {
        // 现在提交
        
        MyTeacherViewController *myTeacherVC = [[MyTeacherViewController alloc]initWithNibName:@"MyTeacherViewController" bundle:nil];
        [self.navigationController pushViewController:myTeacherVC animated:YES];
    }
}


#pragma mark - 界面将要消失
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    NSLog(@"viewWillDisappear");
    audioPlayer.target = nil;
    if (_reduceTimer != nil)
    {
        [self stopTimer];
    }
}

@end
