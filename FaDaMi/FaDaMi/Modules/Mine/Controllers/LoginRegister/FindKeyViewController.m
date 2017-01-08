//
//  FindKeyViewController.m
//  ZhouDao
//
//  Created by apple on 16/3/10.
//  Copyright © 2016年 CQZ. All rights reserved.
//
#import "FindKeyViewController.h"
#import "CCPRestSDK.h"
#import "NSString+MHCommon.h"

@interface FindKeyViewController () <UITextFieldDelegate> {
    
}
@property (nonatomic, copy) NSString *codeStr;//验证码
@property (nonatomic, copy) NSString *phoneString;//验证手机号是否是同一个
@property (nonatomic, assign) BOOL isLook;

@end

@implementation FindKeyViewController

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self initUI];
}
#pragma mark - methods
- (void)initUI { WEAKSELF
    
    _codeStr = @"";
    [self setupNaviBarWithTitle:_navTitle];
    [self setupNaviBarWithBtn:NaviLeftBtn title:@"" img:@"backVC"];
//    [self setEdgesForExtendedLayout:UIRectEdgeNone];
    
    LRViewBorderRadius(_bottomView, 5.f, .5f, hexColor(D7D7D7));
    LRViewBorderRadius(_resetBtn, 5.f, 0.f, [UIColor clearColor]);
    _eyeImg.userInteractionEnabled = YES;

    [_eyeImg whenTapped:^{
        
        [weakSelf dismissKeyBoard];
        if (weakSelf.isLook == YES) {
            weakSelf.eyeImg.image = [UIImage imageNamed:@"find_eye"];
            weakSelf.keyText.secureTextEntry = YES;
        }else {
            weakSelf.eyeImg.image = [UIImage imageNamed:@"find_eyeSelect"];
            weakSelf.keyText.secureTextEntry = NO;
        }
        weakSelf.isLook = !weakSelf.isLook;

    }];
    
    _phoneText.delegate = self;
    _codeText.delegate = self;
    _keyText.delegate = self;
    

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textFieldChanged:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:self.phoneText];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textFieldChanged:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:self.codeText];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textFieldChanged:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:self.keyText];
    
}
- (void)textFieldChanged:(NSNotification*)noti{
    
    UITextField *textField = (UITextField *)noti.object;
    BOOL flag=[NSString isContainsTwoEmoji:textField.text];
    if (flag){
        //SHOW_ALERT(@"不能输入表情!");
        textField.text = [NSString disable_emoji:textField.text];
    }
    
    if (textField.tag == 3000) {
        if (textField.text.length >11) {
            textField.text = [textField.text substringToIndex:11 ];
        }
    }
}
#pragma mark -UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self dismissKeyBoard];
    return true;
}
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}
#pragma mark -UIButtonEvent
- (IBAction)getCodeOrResetEvent:(id)sender { WEAKSELF
    UIButton *btn = (UIButton *)sender;
    NSUInteger index = btn.tag;
    
    switch (index) {
        case 1003: {//获取验证码
            
            if (_phoneText.text.length >0) {
                if (_phoneText.text.length == 11  && [QZManager isPureInt:_phoneText.text] == YES) {
                    
                    [NetWorkMangerTools validationPhoneNumber:_phoneText.text RequestSuccess:^{
                        
                        [JKPromptView showWithImageName:@"" message:@"该号码还没有注册，请您注册"];
                    } fail:^(NSString *msg) {
                        
                        [weakSelf timerInit:sender];
                        CCPRestSDK* ccpRestSdk = [[CCPRestSDK alloc] initWithServerIP:YTXSEVERIP andserverPort:YTXPORT];
                        [ccpRestSdk setApp_ID:YTXAPPID];
                        [ccpRestSdk enableLog:YES];
                        [ccpRestSdk setAccountWithAccountSid: YTXACCOUNSID andAccountToken:YTXAUTHTOKEN];
                        weakSelf.codeStr = [QZManager getSixEvent];
                        NSArray*  arr = [NSArray arrayWithObjects:_codeStr,@"验证码" ,nil];
                        [ccpRestSdk sendTemplateSMSWithTo:_phoneText.text andTemplateId:YTXTEMPLATE andDatas:arr];
                    }];
                }else{
                    [JKPromptView showWithImageName:nil message:LOCCHECKPHONE];
                }
            }else{
                [JKPromptView showWithImageName:nil message:LOCCHECKPHONE];
            }
        }
            break;
        case 1004: {//重置密码
            if (_phoneText.text.length<=0) {
                [JKPromptView showWithImageName:nil message:LOCPHONE];
                return;
            }else if(_phoneText.text.length != 11  || [QZManager isPureInt:_phoneText.text] == NO){
                [JKPromptView showWithImageName:nil message:LOCCHECKPHONE];
                return;
            }else if (_keyText.text.length <=0){
                [JKPromptView showWithImageName:nil message:LOCPASSWORD];
                return;
            }else if(_codeText.text.length <=0){
                [JKPromptView showWithImageName:nil message:LOCVERIFICATION];
                return;
            }else if(![_codeText.text isEqualToString:_codeStr] || ![_phoneText.text isEqualToString:_phoneString]){
                [JKPromptView showWithImageName:nil message:LOCNOTVERIFICATION];
                return;
            }else if ([QZManager isValidatePassword:_keyText.text] == NO)
            {
                [JKPromptView showWithImageName:nil message:LOCPASSWORDLIMIT];
                return;
            }

            [MBProgressHUD showMBLoadingWithText:@"提交中..."];

            NSString *forgetUrl = [NSString stringWithFormat:@"%@%@mobile=%@&pw=%@",kProjectBaseUrl,ForgetKey,_phoneText.text,[_keyText.text md5]];
            [ZhouDao_NetWorkManger getWithUrl:forgetUrl sg_cache:NO success:^(id response) {
                
                [MBProgressHUD hideHUD];
                NSDictionary *jsonDic = (NSDictionary *)response;
                NSUInteger errorcode = [jsonDic[@"state"] integerValue];
                NSString *msg = jsonDic[@"info"];
                if (errorcode !=1) {
                    [MBProgressHUD showError:msg];
                    return ;
                }
                [JKPromptView showWithImageName:nil message:msg];
                
                [USER_D setObject:_phoneText.text forKey:StoragePhone];
                [USER_D setObject:[_keyText.text md5] forKey:StoragePassword];
                //                [USER_D removeObjectForKey:StorageTYPE];
                //                [USER_D removeObjectForKey:StorageUSID];
                
                [USER_D synchronize];
                
                if (weakSelf.findBlock) {
                    weakSelf.findBlock(_phoneText.text);
                }
                [weakSelf.navigationController popViewControllerAnimated:YES];

            } fail:^(NSError *error) {
                [MBProgressHUD showError:LOCERROEMESSAGE];
            }];
            
        }
            break;
        default:
            break;
    }
}

#pragma mark - timer相关
- (void)timerInit:(id)sender {
    
    _phoneString = _phoneText.text;
    JKCountDownButton *btn = (JKCountDownButton *)sender;
    btn.enabled = NO;
    [sender startCountDownWithSecond:60];
    
    [sender countDownChanging:^NSString *(JKCountDownButton *countDownButton,NSUInteger second) {
        NSString *title = [NSString stringWithFormat:@"%zd秒",second];
        return title;
    }];
    [sender countDownFinished:^NSString *(JKCountDownButton *countDownButton, NSUInteger second) {
        countDownButton.enabled = YES;
        return @"重新获取";
        
    }];
}

#pragma mark -手势
- (void)dismissKeyBoard{
    [self.view endEditing:YES];
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self dismissKeyBoard];
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


@end
