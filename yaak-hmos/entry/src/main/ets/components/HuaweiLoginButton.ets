/**
 * HuaweiLoginButton - 华为账号登录按钮组件
 * 使用 LoginWithHuaweiIDButton 实现标准华为账号登录
 * 
 * 注意：这是个人开发者可用的登录方式，不需要企业开发者权限
 */

import { loginComponentManager, LoginWithHuaweiIDButton } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 登录成功回调 - 返回 authorizationCode
 */
export type HuaweiLoginSuccessCallback = (authCode: string, idToken: string) => void;

/**
 * 登录失败回调
 */
export type HuaweiLoginErrorCallback = (errorCode: number, errorMessage: string) => void;

/**
 * 错误码枚举
 */
export enum HuaweiLoginErrorCode {
  ERROR_CODE_LOGIN_OUT = 1001502001,
  ERROR_CODE_NETWORK_ERROR = 1001502005,
  ERROR_CODE_INTERNAL_ERROR = 1001502009,
  ERROR_CODE_USER_CANCEL = 1001502012,
  ERROR_CODE_SYSTEM_SERVICE = 12300001,
  ERROR_CODE_REQUEST_REFUSE = 1001500002,
  ERROR_CODE_AGREEMENT_STATUS_NOT_ACCEPTED = 1005300001
}

/**
 * 登录结果接口
 */
export interface HuaweiLoginResult {
  success: boolean;
  authCode: string;
  idToken: string;
  errorCode: number;
  errorMessage: string;
}

@ComponentV2
export struct HuaweiLoginButton {
  private logTag: string = 'HuaweiLoginButton';
  private domainId: number = 0x0000;

  // 使用 @Event 装饰器处理回调
  @Event onLoginSuccess: HuaweiLoginSuccessCallback = (_authCode: string, _idToken: string) => {};
  @Event onLoginError: HuaweiLoginErrorCallback = (_code: number, _msg: string) => {};
  
  @Param buttonStyle: string = 'red';

  // 构造 LoginWithHuaweiIDButton 组件的控制器
  controller: loginComponentManager.LoginWithHuaweiIDButtonController =
    new loginComponentManager.LoginWithHuaweiIDButtonController()
      .onClickLoginWithHuaweiIDButton((error: BusinessError | undefined,
        response: loginComponentManager.HuaweiIDCredential) => {
        this.handleLoginResult(error, response);
      });

  /**
   * 处理登录结果
   */
  private handleLoginResult(error: BusinessError | undefined,
    response: loginComponentManager.HuaweiIDCredential): void {
    if (error) {
      hilog.error(this.domainId, this.logTag,
        `Login error: ${error.code}, ${error.message}`);
      this.handleError(error);
      return;
    }

    if (response) {
      hilog.info(this.domainId, this.logTag, 'Login success');
      const authCode: string = response.authorizationCode || '';
      const idToken: string = response.idToken || '';
      this.onLoginSuccess(authCode, idToken);
    }
  }

  /**
   * 处理错误
   */
  private handleError(error: BusinessError): void {
    let errorMessage: string = '';

    if (error.code === HuaweiLoginErrorCode.ERROR_CODE_LOGIN_OUT) {
      errorMessage = '华为账号未登录，请先登录华为账号';
    } else if (error.code === HuaweiLoginErrorCode.ERROR_CODE_NETWORK_ERROR) {
      errorMessage = '网络异常，请检查网络设置';
    } else if (error.code === HuaweiLoginErrorCode.ERROR_CODE_INTERNAL_ERROR) {
      errorMessage = '登录失败，请稍后重试';
    } else if (error.code === HuaweiLoginErrorCode.ERROR_CODE_USER_CANCEL) {
      errorMessage = '用户取消登录';
    } else if (error.code === HuaweiLoginErrorCode.ERROR_CODE_SYSTEM_SERVICE) {
      errorMessage = '系统服务异常，请稍后重试';
    } else if (error.code === HuaweiLoginErrorCode.ERROR_CODE_REQUEST_REFUSE) {
      errorMessage = '请勿重复请求';
    } else if (error.code === HuaweiLoginErrorCode.ERROR_CODE_AGREEMENT_STATUS_NOT_ACCEPTED) {
      errorMessage = '请先同意用户协议';
    } else {
      errorMessage = error.message || '登录失败';
    }

    this.onLoginError(error.code, errorMessage);
  }

  /**
   * 获取按钮样式
   */
  private getButtonStyle(): loginComponentManager.Style {
    if (this.buttonStyle === 'white') {
      return loginComponentManager.Style.BUTTON_WHITE;
    } else if (this.buttonStyle === 'black') {
      return loginComponentManager.Style.BUTTON_BLACK;
    }
    return loginComponentManager.Style.BUTTON_RED;
  }

  build() {
    Column() {
      LoginWithHuaweiIDButton({
        params: {
          // 按钮样式
          style: this.getButtonStyle(),
          // 登录过程中展示加载态
          extraStyle: {
            buttonStyle: new loginComponentManager.ButtonStyle().loadingStyle({
              show: true
            })
          },
          // 登录类型：ID 登录（个人开发者可用）
          loginType: loginComponentManager.LoginType.ID,
          // 跟随系统深浅色模式
          supportDarkMode: true
        },
        controller: this.controller
      })
    }
    .height(40)
    .width('100%')
  }
}
