//
//  CheckBlankViewController.m
//  oral
//
//  Created by cocim01 on 15/5/20.
//  Copyright (c) 2015年 keximeng. All rights reserved.
//

#import "CheckBlankViewController.h"
#import "AudioPlayer.h"
#import "CheckSuccessViewController.h"
#import "TPCCheckpointViewController.h"
#import "DFAiengineSentObject.h"



@interface CheckBlankViewController ()<DFAiengineSentProtocol,UIWebViewDelegate>
{
    NSDictionary *_topicInfoDict;// 整个topic信息
    NSDictionary *_currentPartDict;// 当前part资源信息
    NSDictionary *_currentPointDict;// 当前关卡资源信息
    NSArray *_questioListArray;
    NSArray *_currentAnswerListArray;
    
    NSInteger _sumQuestionCounts;//总的问题个数
    NSInteger _currentQuestionCounts;// 当前进行的问题
    NSInteger _sumAnswerCounts;//当前问题的总回答数
    NSInteger _currentAnswerCounts;// 当前回答数
    
    BOOL _currentQuestionFinished;
    BOOL _startAnswer;
    
    AudioPlayer *audioPlayer;
    
    NSInteger _answerTime;//跟读时间
    NSTimer *_reduceTimer;
    CGRect _timeProgressRect;// 用于标记时间进度条的原始frame
    
    DFAiengineSentObject *_dfEngine;
}
@end

@implementation CheckBlankViewController
#define kTopQueCountButtonTag 555
#define kFollowLabelTag 333
#define kAnswerTextLabelTag 334
#define kQuestionTextLabelTag 335

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    
    _answerTime = 15;
    audioPlayer = [AudioPlayer getAudioManager];
    audioPlayer.target = self;
    audioPlayer.action = @selector(playerEnd);
    _currentPointCounts = 1;

    NSString *title = [NSString stringWithFormat:@"Part%ld-%ld",self.currentPartCounts+1,_currentPointCounts+1];
    [self addTitleLabelWithTitleWithTitle:title];
    self.navTopView.backgroundColor = _backColor;
    self.titleLab.textColor = [UIColor whiteColor];
    
    self.view.backgroundColor = [UIColor colorWithRed:245/255.0 green:249/255.0 blue:250/255.0 alpha:1];
    [self moNiDataFromLocal];
    [self uiConfig];
    [self createTipLabel];
    
    _dfEngine = [[DFAiengineSentObject alloc]initSentEngine:self withUser:@"haiyan"];
}

#pragma mark - UI布局
#pragma mark - - 创建提示标签
// 用于提示用户操作成功
- (void)createTipLabel
{
    UILabel *tipLab = [[UILabel alloc]initWithFrame:CGRectMake((kScreentWidth-100)/2, kScreenHeight-35, 0, 0)];
    tipLab.tag = 1111;
    tipLab.text = @"成功加入练习簿";
    tipLab.backgroundColor = [UIColor clearColor];
    tipLab.textAlignment = NSTextAlignmentCenter;
    tipLab.textColor = _pointColor;
    tipLab.font = [UIFont systemFontOfSize:KFourFontSize];
    tipLab.layer.masksToBounds = YES;
    tipLab.layer.cornerRadius = 3;
    tipLab.layer.borderColor = _pointColor.CGColor;
    tipLab.layer.borderWidth = 1;
    [self.view addSubview:tipLab];
}

#pragma mark - UI配置
- (void)uiConfig
{
    // 顶部 问题是个数显示区域
    // 背景颜色 去掉
    _topQuestionCountView.backgroundColor = [UIColor clearColor];
    // 计算出按钮高度  不同尺寸屏幕 高度不同
    NSInteger partCountViewHeight = _topQuestionCountView.frame.size.height;
    NSInteger btnWid = 30;
    // 根据总问题数创建按钮
    for (int i = 0; i < _sumQuestionCounts; i ++)
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setFrame:CGRectMake(20+i*(btnWid+10), (partCountViewHeight-btnWid)/2, btnWid, btnWid)];
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
        [_topQuestionCountView addSubview:btn];
    }
    
    
    // 老师部分控件
    _teacherView.backgroundColor = [UIColor clearColor];
    // 老师头像 --- 设置圆角半径 layer
    _teaHeadImgView.layer.masksToBounds = YES;
    _teaHeadImgView.layer.cornerRadius = _teaHeadImgView.bounds.size.height/2;
    _teaHeadImgView.layer.borderColor = _backColor.CGColor;
    _teaHeadImgView.layer.borderWidth = 2;
    [_teaHeadImgView setImage:[UIImage imageNamed:@"touxiang"]];
    
    // 问题背景----layer
    _teaQuestionLabel.layer.masksToBounds = YES;
    _teaQuestionLabel.layer.cornerRadius = _teaQuestionLabel.frame.size.height/1334*kScreenHeight;
    // 问题文本 多行显示
    _teaQuestionLabel.text = @"";//起始为空
    _teaQuestionLabel.textColor = _textColor;
    _teaQuestionLabel.textAlignment = NSTextAlignmentCenter;
    _teaQuestionLabel.numberOfLines = 0;
    _teaQuestionLabel.backgroundColor = [UIColor clearColor];
    
    _teaQuestionBackView.layer.masksToBounds = YES;
    _teaQuestionBackView.layer.cornerRadius = _teaQuestionLabel.frame.size.height/2;
    _teaQuestionBackView.backgroundColor = [UIColor whiteColor];

    
    // 学生部分控件
//    UIColor *stuColor = _backColor;
    _studentView.backgroundColor = [UIColor whiteColor];
    _stuFollowLabel.textColor = _backColor;//跟读颜色
    _stuFollowLabel.text = @"";//起始为空
    [self changeAnswerProgress];//当前回答数：1
    _stuCountLabel.textColor = _backColor;
    
//    _stuAnswerLabel.text = @"";//起始为空
//    _stuAnswerLabel.textColor = _textColor;
    
    _StuAnswerWebView.delegate = self;
    _stuLineLabel.backgroundColor = [UIColor colorWithWhite:248/255.0 alpha:1];
    // 时间进度条
    _stuTimeProgressLabel.backgroundColor = _backColor;
    
    
    _studentView.frame = CGRectMake(15, 215, kScreentWidth-30,  kScreenHeight-215-160);
    
    // 标记时间进度条原始frame
    CGRect rect = _stuTimeProgressLabel.frame;
    rect.size.width = kScreentWidth-130;
    rect.origin.x = 8;
    rect.origin.y = _studentView.frame.size.height-36;
    _stuTimeProgressLabel.frame = rect;
    _timeProgressRect = rect;
    // 学生头像
    _stuHeadImgView.layer.masksToBounds = YES;
    _stuHeadImgView.layer.cornerRadius = _stuHeadImgView.frame.size.height/2;
    _stuHeadImgView.layer.borderWidth = 2;
    _stuHeadImgView.layer.borderColor = _backColor.CGColor;
    
    // 分数按钮
    _stuScoreButton.layer.cornerRadius = _stuScoreButton.frame.size.height/2;
    [_stuScoreButton setBackgroundColor:_backColor];
    //隐藏跟读按钮
    _followAnswerButton.hidden = YES;
    [_followAnswerButton setBackgroundImage:[UIImage imageNamed:@"answerButton-sele"] forState:UIControlStateNormal];
    [_followAnswerButton setBackgroundImage:[UIImage imageNamed:@"answerButton-sele"] forState:UIControlStateSelected];
    
    // 下一题
    [_continueButton setTitleColor:_pointColor forState:UIControlStateNormal];
    [_continueButton setAdjustsImageWhenHighlighted:NO];
    _continueButton.layer.masksToBounds = YES;
    _continueButton.layer.cornerRadius = _continueButton.frame.size.height/2;
    [_continueButton setBackgroundColor:[UIColor whiteColor]];
    
    _continueButton.hidden = YES;
    [_continueButton setTitleColor:kPart_Button_Color forState:UIControlStateNormal];
    
    // 起始状态：老师头像暗 学生头像 暗 文本不显示
    _teaHeadImgView.alpha = 0.3;
    _stuHeadImgView.alpha = 0.3;
    _teaQuestionLabel.text = @"";
//    _stuAnswerLabel.text = @"";
    
    _stuFollowLabel.tag = kFollowLabelTag;
    _teaQuestionLabel.tag = kQuestionTextLabelTag;
    
    // 回答区域圆角
    _studentView.layer.cornerRadius = 5;
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
    
    // 当前进行的问题的回答列表
    _currentAnswerListArray = [[_questioListArray objectAtIndex:_currentQuestionCounts] objectForKey:@"answerlist"];
    // 当前问题回答数
    _sumAnswerCounts = _currentAnswerListArray.count;
    // 正在回答数
    _currentAnswerCounts = 0;
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


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self prepareQuestion];
}

#pragma mark - 各阶段逻辑
/*
 以下： 播放问题音频、回答音频 开始跟读 均采用定时器延时 为了实现界面控件先后动画
 */
#pragma mark - - 播放问题准备
- (void)prepareQuestion
{
//    _teaQuestionLabel.font = [UIFont systemFontOfSize:0];
    [self showCurrentQuestionText];
    [self textAnimationInView:_teaQuestionLabel];
    
    [UIView animateWithDuration:2 animations:^{
        _teaQuestionLabel.font = [UIFont systemFontOfSize:KThidFontSize];
        _teaHeadImgView.alpha = 1;
        _stuHeadImgView.alpha = 0.3;
    }];
    
    _reduceTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(willPlayQuestion) userInfo:nil repeats:NO];
}

- (void)willPlayQuestion
{
    [_reduceTimer invalidate];
    _reduceTimer = nil;
    [self playQuestion];
}

#pragma mark - 跟读准备
- (void)prepareBlank
{
    // 1、展示answer的文本
    [self showCurrentAnswerText];
    // 后续的动画
    _reduceTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(blankTextShow) userInfo:nil repeats:NO];
}

#pragma mark - 显示-->请跟读
- (void)blankTextShow
{
    [self stopReduceTimer];
    _stuFollowLabel.text = @"请填空";
    [self textAnimationInView:_stuFollowLabel];
    
    [UIView animateWithDuration:1 animations:^{
        _stuFollowLabel.text = @"请填空";
    }];
    _reduceTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(stuImageBrite_Blank) userInfo:nil repeats:NO];
}
#pragma mark ---头像-->亮
- (void)stuImageBrite_Blank
{
    [self stopReduceTimer];
    [UIView animateWithDuration:1 animations:^{
        _stuHeadImgView.alpha = 1;
        _teaHeadImgView.alpha = 0.3;
    }];
    _reduceTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(willFollowRecord_blank) userInfo:nil repeats:NO];
}

#pragma mark ---跟读按钮-->显示
- (void)willFollowRecord_blank
{
    [_reduceTimer invalidate];
    _reduceTimer = nil;
    _followAnswerButton.hidden = NO;// 展示跟读按钮
    [self followAnswerButtonClicked:_followAnswerButton];
}

#pragma mark - - 文字动画
- (void)textAnimationInView:(UILabel *)lable
{
    [UIView beginAnimations:@"animationID" context:nil];
    [UIView setAnimationDuration:1.0f];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationRepeatAutoreverses:NO];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:lable cache:YES];
    [self showCurrentQuestionText];
    [self.view exchangeSubviewAtIndex:1 withSubviewAtIndex:0];
    [UIView commitAnimations];
}


#pragma mark - 播放器
#pragma mark -- 播放完成回调
- (void)playerEnd
{
    NSLog(@"playerCallBack");
    // 跟读 录音 (思必驰)
    [self prepareBlank];
}

#pragma mark -- 播放问题音频
- (void)playQuestion
{
    if (_reduceTimer)
    {
        [self stopReduceTimer];
    }
    // 获取音频路径
    NSString *audiourl = [[_questioListArray objectAtIndex:_currentQuestionCounts] objectForKey:@"audiourl"];
    NSString *audioPath = [NSHomeDirectory() stringByAppendingFormat:@"/Documents/%@/topicResource/temp/%@",self.topicName,audiourl];

    [audioPlayer playerPlayWithFilePath:audioPath];
}


#pragma mark - 切换问题变换文本
#pragma mark -- 展示问题文本
- (void)showCurrentQuestionText
{
    _teaQuestionLabel.text = [[_questioListArray objectAtIndex:_currentQuestionCounts] objectForKey:@"question"];
}

#pragma mark -- 展示回答文本
- (void)showCurrentAnswerText
{
    _currentAnswerListArray = [[_questioListArray objectAtIndex:_currentQuestionCounts] objectForKey:@"answerlist"];
    NSString *answerTextBlank = [self makeUpBlankStringWithDict:[_currentAnswerListArray objectAtIndex:_currentAnswerCounts]];
    [_StuAnswerWebView loadHTMLString:answerTextBlank baseURL:nil];
}

#pragma mark - 去掉html标签 (改用webView 此方法已不需要 暂时保留 2015.06.11)
-(NSString *)filterHTML:(NSString *)html
{
    NSScanner * scanner = [NSScanner scannerWithString:html];
    NSString * text = nil;
    while([scanner isAtEnd]==NO)
    {
        //找到标签的起始位置
        [scanner scanUpToString:@"<" intoString:nil];
        //找到标签的结束位置
        [scanner scanUpToString:@">" intoString:&text];
        //替换字符
        html = [html stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@>",text] withString:@""];
    }
    //    NSString * regEx = @"<([^>]*)>";
    //    html = [html stringByReplacingOccurrencesOfString:regEx withString:@""];
    return html;
}

#pragma mark - 组成填空的字符串
- (NSString *)makeUpBlankStringWithDict:(NSDictionary *)dict
{
    NSMutableString *blankStr = [NSMutableString stringWithString:[self filterHTML:[dict objectForKey:@"answer"]]];
    NSString *keyWord = [self filterHTML:[dict objectForKey:@"keyword"]];
    NSArray *keyArray = [keyWord componentsSeparatedByString:@"||"];
    for (int i = 0; i < keyArray.count; i ++)
    {
        NSRange keyRange = [blankStr rangeOfString:[keyArray objectAtIndex:i]];
        if (keyRange.location != NSNotFound)
        {
            [blankStr replaceCharactersInRange:keyRange withString:@"______"];
        }
    }
    return blankStr;
}

#pragma mark - 模拟思必驰反馈
#pragma mark - 开启思必驰
- (void)startSBCAiengine
{
    NSString *text = [[_currentAnswerListArray objectAtIndex:_currentAnswerCounts] objectForKey:@"answer"];
    if(_dfEngine)
        [_dfEngine startEngineFor:[self filterHTML:text]];
}

#pragma mark  - 停止思必驰
- (void)stopSBCAiengine
{
    // 展示分数
    [_dfEngine stopEngine];
}

#pragma mark - 思必驰反馈
-(void)processAiengineSentResult:(DFAiengineSentResult *)result
{
    NSDictionary *fluency = result.fluency;
    NSString *msg = [NSString stringWithFormat:@"总体评分：%d\n发音：%d，完整度：%d，流利度：%d", result.overall, result.pron, result.integrity, ((NSNumber *)[fluency objectForKey:@"overall"]).intValue];
    NSLog(@"%@",msg);
    [self performSelectorOnMainThread:@selector(showResult:) withObject:[NSString stringWithFormat:@"%d",result.overall] waitUntilDone:NO];
    
    NSString *msg1 = [_dfEngine getRichResultString:result.details];
    NSLog(@"%@",msg1);
    [self performSelectorOnMainThread:@selector(showHtmlMsg:) withObject:msg1 waitUntilDone:NO];
    
}

#pragma mark - - 展示每个单词发音情况
- (void)showHtmlMsg:(NSString *)htmlStr
{
    // 展示每个单词发音情况
    [_StuAnswerWebView loadHTMLString:htmlStr baseURL:nil];
}

#pragma mark - 展示分数
- (void)showResult:(NSString *)score
{
    _stuTimeProgressLabel.hidden = YES;// 隐藏时间进度条
    _stuTimeProgressLabel.frame = _timeProgressRect;//回复时间进度条 以便下次使用
    _stuHeadImgView.hidden = YES;// 隐藏学生头像
    _stuScoreButton.hidden = NO; // 展示分数区域
    /*
     根据反馈结果填空
     0,213,136  绿色  80<=x<=100
     246,215,0  黄色  60<=x<80
     212,0,44   红色   0<=x<60
     待完善
     */
    NSArray *colorArray = @[_perfColor,_goodColor,_badColor];
    int scoreCun = [score intValue]>=80?0:([score intValue]>=60?1:2);
    [_stuScoreButton setTitle:score forState:UIControlStateNormal];
    [_stuScoreButton setBackgroundColor:[colorArray objectAtIndex:scoreCun]];
    
    // 隐藏回答按钮  展示下一题区域
    _followAnswerButton.hidden = YES;
    _continueButton.hidden = NO;
    _stuHeadImgView.alpha = 0.3;
    [_continueButton setTitleColor:kPart_Button_Color forState:UIControlStateNormal];
}

#pragma mark - 定时器
#pragma mark -- 时间倒计时
- (void)timeReduce
{
    CGRect rect = _stuTimeProgressLabel.frame;
    rect.origin.x ++;
    rect.size.width --;
    _stuTimeProgressLabel.frame = rect;
    if (rect.size.width<=0)
    {
        [self stopReduceTimer];
        //倒计时结束 停止跟读
        [self followAnswerButtonClicked:_followAnswerButton];
        _followAnswerButton.hidden = YES;
    }
}

#pragma mark -- 关闭定时器
- (void)stopReduceTimer
{
    [_reduceTimer invalidate];
    _reduceTimer = nil;
}

#pragma mark - 下一题
- (IBAction)continueButtonClicked:(id)sender
{
    // 下一题
    _reduceTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(jugePointIsFinished) userInfo:nil repeats:NO];
}

#pragma mark - 跟读按钮被点击
- (IBAction)followAnswerButtonClicked:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    if (btn.selected)
    {
        btn.selected = NO;
        // 停止倒计时
        [self stopReduceTimer];
        // 停止sbc
        [self stopSBCAiengine];
    }
    else
    {
        btn.selected = YES;
        // 开启思必驰
        [self startSBCAiengine];
        // 时间进度条变化
        _stuTimeProgressLabel.frame = _timeProgressRect;
        _reduceTimer = [NSTimer scheduledTimerWithTimeInterval:15/_timeProgressRect.size.width target:self selector:@selector(timeReduce) userInfo:nil repeats:YES];
    }
}


#pragma mark - 下一问题
- (void)next
{
    _stuFollowLabel.text = @"";
    if (_currentAnswerCounts<_sumAnswerCounts)
    {
        // 继续当前问题
        [self changeAnswerProgress];
        _startAnswer = YES;//标记 用于播放器回调方法
        [self prepareBlank];
    }
    else
    {
        // 下一题
        [self questionCountChanged];//标记当前进行的问题数
        [self changeAnswerProgress];
        _currentAnswerListArray = [[_questioListArray objectAtIndex:_currentQuestionCounts] objectForKey:@"answerlist"];
        [self prepareQuestion];
    }
}



#pragma mark - 判断闯关是否结束
- (void)jugePointIsFinished
{
    [self stopReduceTimer];
    _answerTime = 15;
    // 隐藏下一问题按钮区域
    _continueButton.hidden = YES;
    _continueButton.selected = NO;
    // 隐藏分数 显示学生头像 时间进度条
    _stuScoreButton.hidden = YES;
    _stuTimeProgressLabel.hidden = NO;
    _stuHeadImgView.hidden = NO;
    
    _currentAnswerCounts++;// 当前回答数+1
    if (_currentAnswerCounts>=_sumAnswerCounts)
    {
        _currentAnswerCounts = 0;
        _currentQuestionCounts ++;
        if (_currentQuestionCounts<_sumQuestionCounts)
        {
            // 下一题
            [self questionCountChanged];//标记当前进行的问题数
            // 继续当前问题
            [self changeAnswerProgress];
            _currentAnswerListArray = [[_questioListArray objectAtIndex:_currentQuestionCounts] objectForKey:@"answerlist"];
            [self prepareQuestion];
        }
        else
        {
            //关卡结束 跳转过渡页
            CheckSuccessViewController *successVC = [[CheckSuccessViewController alloc]initWithNibName:@"CheckSuccessViewController" bundle:nil];
            successVC.pointCount = self.currentPointCounts;
            successVC.topicName = self.topicName;
            [self.navigationController pushViewController:successVC animated:YES];
        }
        
    }
    else
    {
        // 继续当前问题
        [self changeAnswerProgress];
        _startAnswer = YES;//标记 用于播放器回调方法
        [self prepareBlank];
    }
}


#pragma mark -- 标记当前进行的问题数
- (void)questionCountChanged
{
    for (int i = 0; i < _sumQuestionCounts; i ++)
    {
        UIButton *btn = (UIButton *)[self.view viewWithTag:kTopQueCountButtonTag+i];
        if (i == _currentQuestionCounts)
        {
            btn.selected = YES;
        }
        else
        {
            btn.selected = NO;
        }
    }
}



#pragma mark -- 动态改变当前回答进度
- (void)changeAnswerProgress
{
    _stuCountLabel.text = [NSString stringWithFormat:@"%ld/%ld",_currentAnswerCounts+1,_sumAnswerCounts];
}

#pragma mark - 界面将要消失
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    NSLog(@"viewWillDisappear");
    audioPlayer.target = nil;
    if (_reduceTimer != nil)
    {
        [self stopReduceTimer];
    }
    if (_dfEngine)
    {
        [_dfEngine stopEngine];
        _dfEngine = nil;
    }
}
@end
