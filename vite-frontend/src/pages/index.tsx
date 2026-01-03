import { Button } from "@heroui/button";
import { Input } from "@heroui/input";
import { Card, CardBody, CardHeader } from "@heroui/card";
import { useState, useEffect, useRef } from "react";
import { useNavigate } from "react-router-dom";
import toast from 'react-hot-toast';
import { Turnstile } from '@marsidev/react-turnstile';
import { isWebViewFunc } from '@/utils/panel';
import { siteConfig } from '@/config/site';
import { title } from "@/components/primitives";
import DefaultLayout from "@/layouts/default";
import { login, LoginData, checkCaptcha, verifyTurnstile } from "@/api";


interface LoginForm {
  username: string;
  password: string;
  captchaId: string;
}

export default function IndexPage() {
  const [form, setForm] = useState<LoginForm>({
    username: "",
    password: "",
    captchaId: "",
  });
  const [loading, setLoading] = useState(false);
  const [errors, setErrors] = useState<Partial<LoginForm>>({});
  const [showCaptcha, setShowCaptcha] = useState(false);
  const [turnstileSiteKey, setTurnstileSiteKey] = useState<string>(''); // Turnstile Site Key
  const navigate = useNavigate();
  const turnstileRef = useRef<any>(null);
  const [isWebView, setIsWebView] = useState(false);

  // 检测是否在WebView中运行
  useEffect(() => {
    setIsWebView(isWebViewFunc());
  }, []);

  // 验证表单
  const validateForm = (): boolean => {
    const newErrors: Partial<LoginForm> = {};

    if (!form.username.trim()) {
      newErrors.username = '请输入用户名';
    }

    if (!form.password.trim()) {
      newErrors.password = '请输入密码';
    } else if (form.password.length < 6) {
      newErrors.password = '密码长度至少6位';
    }


    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  // 处理输入变化
  const handleInputChange = (field: keyof LoginForm, value: string) => {
    setForm(prev => ({ ...prev, [field]: value }));
    // 清除该字段的错误
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: undefined }));
    }
  };

  // 处理 Turnstile 验证成功
  const handleTurnstileSuccess = async (token: string) => {
    try {
      // 调用后端验证 Turnstile token
      const response = await verifyTurnstile(token);
      if (response.code === 0 && response.data?.validToken) {
        form.captchaId = response.data.validToken;
        setShowCaptcha(false);
        await performLogin();
      } else {
        toast.error('人机验证失败，请重试');
        // 重置 Turnstile
        if (turnstileRef.current) {
          turnstileRef.current.reset();
        }
      }
    } catch (error) {
      console.error('Turnstile 验证失败:', error);
      toast.error('验证失败，请重试');
      if (turnstileRef.current) {
        turnstileRef.current.reset();
      }
    }
  };

  // 处理 Turnstile 验证错误
  const handleTurnstileError = () => {
    toast.error('人机验证加载失败，请刷新页面重试');
    setShowCaptcha(false);
    setLoading(false);
  };

  // 执行登录请求
  const performLogin = async () => {


    try {
      const loginData: LoginData = {
        username: form.username.trim(),
        password: form.password,
        captchaId: form.captchaId,
      };

      const response = await login(loginData);
      
      if (response.code !== 0) {
        toast.error(response.msg || "登录失败");
        return;
      }

      // 检查是否需要强制修改密码
      if (response.data.requirePasswordChange) {
        localStorage.setItem('token', response.data.token);
        localStorage.setItem("role_id", response.data.role_id.toString());
        localStorage.setItem("name", response.data.name);
        localStorage.setItem("admin", (response.data.role_id === 0).toString());
        toast.success('检测到默认密码，即将跳转到修改密码页面');
        navigate("/change-password");
        return;
      }

      // 保存登录信息
      localStorage.setItem('token', response.data.token);
      localStorage.setItem("role_id", response.data.role_id.toString());
      localStorage.setItem("name", response.data.name);
      localStorage.setItem("admin", (response.data.role_id === 0).toString());

      // 登录成功
      toast.success('登录成功');
      navigate("/dashboard");

    } catch (error) {
      console.error('登录错误:', error);
      toast.error("网络错误，请稍后重试");
    } finally {
      setLoading(false);
    }
  };

  const handleLogin = async () => {
    if (!validateForm()) return;

    setLoading(true);

    try {
      // 先检查是否需要验证码
      const checkResponse = await checkCaptcha();
      
      if (checkResponse.code !== 0) {
        toast.error("检查验证码状态失败，请重试" + checkResponse.msg);
        setLoading(false);
        return;
      }

      // 返回数据结构：{ enabled: 0/1, type: "TURNSTILE", turnstile_site_key: string }
      const captchaData = checkResponse.data;
      
      // 检查是否启用验证码
      if (captchaData === 0 || captchaData?.enabled === 0) {
        // 不需要验证码，直接登录
        await performLogin();
      } else {
        // 需要 Turnstile 验证码
        const siteKey = captchaData?.turnstile_site_key || '';
        if (!siteKey) {
          toast.error('Turnstile 配置错误：缺少 Site Key');
          setLoading(false);
          return;
        }
        setTurnstileSiteKey(siteKey);
        setShowCaptcha(true);
      }
    } catch (error) {
      console.error('检查验证码状态错误:', error);
      toast.error("网络错误，请稍后重试" + error);
      setLoading(false);
    }
  };


  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !loading) {
      handleLogin();
    }
  };

  return (
    <DefaultLayout>
      <section className="flex flex-col items-center justify-center gap-4 py-4 sm:py-8 md:py-10 pb-20 min-h-[calc(100dvh-120px)] sm:min-h-[calc(100dvh-200px)]">
        <div className="w-full max-w-md px-4 sm:px-0">
          <Card className="w-full">
            <CardHeader className="pb-0 pt-6 px-6 flex-col items-center">
              <h1 className={title({ size: "sm" })}>登陆</h1>
              <p className="text-small text-default-500 mt-2">请输入您的账号信息</p>
            </CardHeader>
            <CardBody className="px-6 py-6">
              <div className="flex flex-col gap-4">
                <Input
                  label="用户名"
                  placeholder="请输入用户名"
                  value={form.username}
                  onChange={(e) => handleInputChange('username', e.target.value)}
                  onKeyDown={handleKeyPress}
                  variant="bordered"
                  isDisabled={loading}
                  isInvalid={!!errors.username}
                  errorMessage={errors.username}
                />
                
                <Input
                  label="密码"
                  placeholder="请输入密码"
                  type="password"
                  value={form.password}
                  onChange={(e) => handleInputChange('password', e.target.value)}
                  onKeyDown={handleKeyPress}
                  variant="bordered"
                  isDisabled={loading}
                  isInvalid={!!errors.password}
                />

                
                <Button
                  color="primary"
                  size="lg"
                  onClick={handleLogin}
                  isLoading={loading}
                  disabled={loading}
                  className="mt-2"
                >
                  {loading ? (showCaptcha ? "验证中..." : "登录中...") : "登录"}
                </Button>
              </div>
            </CardBody>
          </Card>
        </div>


      {/* 版权信息 - 固定在底部，不占据布局空间 */}
      
               <div className="fixed inset-x-0 bottom-4 text-center py-4">
               <p className="text-xs text-gray-400 dark:text-gray-500">
                 Powered by{' '}
                 <a 
                   href="https://github.com/missuo/flux-panel" 
                   target="_blank" 
                   rel="noopener noreferrer"
                   className="text-gray-500 dark:text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition-colors"
                 >
                   flux-panel
                 </a>
               </p>
               <p className="text-xs text-gray-400 dark:text-gray-500 mt-1">
                 v{ isWebView ? siteConfig.app_version : siteConfig.version}
               </p>
             </div>
      
   

        {/* 验证码弹层 */}
        {showCaptcha && (
          <div className="fixed inset-0 z-50 flex items-center justify-center">
            {/* 背景遮罩层 - 模糊效果，暗黑模式下更深 */}
            <div 
              className="absolute inset-0 bg-black/60 dark:bg-black/80 backdrop-blur-sm" 
              onClick={() => {
                setShowCaptcha(false);
                setLoading(false);
              }}
            />
            {/* Turnstile 验证码容器 */}
            <div className="relative z-10 bg-white dark:bg-gray-800 rounded-lg p-6 shadow-xl">
              <div className="text-center mb-4">
                <h3 className="text-lg font-semibold text-gray-900 dark:text-white">人机验证</h3>
                <p className="text-sm text-gray-500 dark:text-gray-400">请完成以下验证以继续</p>
              </div>
              <Turnstile
                ref={turnstileRef}
                siteKey={turnstileSiteKey}
                onSuccess={handleTurnstileSuccess}
                onError={handleTurnstileError}
                onExpire={() => {
                  toast.error('验证已过期，请重试');
                  if (turnstileRef.current) {
                    turnstileRef.current.reset();
                  }
                }}
                options={{
                  theme: document.documentElement.classList.contains('dark') || 
                         document.documentElement.getAttribute('data-theme') === 'dark' ||
                         window.matchMedia('(prefers-color-scheme: dark)').matches 
                         ? 'dark' : 'light',
                  size: 'normal'
                }}
              />
              <button
                onClick={() => {
                  setShowCaptcha(false);
                  setLoading(false);
                }}
                className="mt-4 w-full text-center text-sm text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300"
              >
                取消
              </button>
            </div>
          </div>
        )}
      </section>
    </DefaultLayout>
  );
}
