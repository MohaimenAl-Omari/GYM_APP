import 'package:get/get.dart';
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': _en,
        'ar_SA': _ar,
      };

  static const Map<String, String> _en = {
    // Shared
    'password': 'Password',
    'login': 'Login',
    'or_continue_with': 'Or continue with',
    'or_sign_up_with': 'Or sign up with',
    'google': 'Google',
    'apple': 'Apple',
    'loading': 'Loading...',

    // Login screen
    'welcome_back': 'Welcome Back',
    'login_subtitle': 'Login to continue your fitness journey',
    'email_address': 'Email Address',
    'forgot_password': 'Forgot Password?',
    'no_account': "Don't have an account?  ",
    'sign_up': 'Sign Up',
    'logged_in_google': 'Logged in with Google!',
    'google_login_failed': 'Google login failed.',

    // Register screen
    'create_account': 'Create Account',
    'register_subtitle': 'Start your fitness journey today \u{1F4AA}',
    'full_name': 'Full Name',
    'phone_number': 'Phone Number',
    'confirm_password': 'Confirm Password',
    'creating_account': 'Creating account...',
    'already_have_account': 'Already have an account?  ',
    'please_fill_all_fields': 'Please fill in all fields.',
    'password_min_length': 'Password must be at least 8 characters.',
    'passwords_do_not_match': 'Passwords do not match.',
    'account_created_successfully': 'Account created successfully!',
    'account_created_google': 'Account created with Google!',
    'google_signup_failed': 'Google sign up failed.',

    // Complete profile screen
    'complete_profile_title': 'Complete Your Profile',
    'complete_profile_subtitle':
        'Just a few more details to personalize your plan',
    'age': 'Age',
    'weight': 'Weight',
    'height': 'Height (cm)',
    'goal': 'Your Goal',
    'goal_lose_weight': 'Lose Weight',
    'goal_build_muscle': 'Build Muscle',
    'goal_improve_fitness': 'Improve Fitness',
    'goal_maintain_weight': 'Maintain Weight',
    'kg': 'kg',
    'lbs': 'lbs',
    'continue_label': 'Continue',
    'saving': 'Saving...',
    'invalid_age': 'Please enter a valid age.',
    'invalid_weight': 'Please enter a valid weight.',
    'invalid_height': 'Please enter a valid height.',
    'please_select_goal': 'Please select your goal.',

    // Home placeholder
    'home_welcome_title': "You're all set!",
    'home_welcome_subtitle': 'Your dashboard is coming soon.',
    'logout': 'Logout',
  };

  static const Map<String, String> _ar = {
    // Shared
    'password': 'كلمة المرور',
    'login': 'تسجيل الدخول',
    'or_continue_with': 'أو تابع باستخدام',
    'or_sign_up_with': 'أو أنشئ حسابًا باستخدام',
    'google': 'جوجل',
    'apple': 'أبل',
    'loading': 'جارٍ التحميل...',

    // Login screen
    'welcome_back': 'مرحبًا بعودتك',
    'login_subtitle': 'سجّل الدخول لمتابعة رحلتك الرياضية',
    'email_address': 'البريد الإلكتروني',
    'forgot_password': 'هل نسيت كلمة المرور؟',
    'no_account': 'ليس لديك حساب؟  ',
    'sign_up': 'إنشاء حساب',
    'logged_in_google': 'تم تسجيل الدخول عبر جوجل!',
    'google_login_failed': 'فشل تسجيل الدخول عبر جوجل.',

    // Register screen
    'create_account': 'إنشاء حساب',
    'register_subtitle': 'ابدأ رحلتك الرياضية اليوم \u{1F4AA}',
    'full_name': 'الاسم الكامل',
    'phone_number': 'رقم الهاتف',
    'confirm_password': 'تأكيد كلمة المرور',
    'creating_account': 'جارٍ إنشاء الحساب...',
    'already_have_account': 'لديك حساب بالفعل؟  ',
    'please_fill_all_fields': 'يرجى تعبئة جميع الحقول.',
    'password_min_length': 'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل.',
    'passwords_do_not_match': 'كلمتا المرور غير متطابقتين.',
    'account_created_successfully': 'تم إنشاء الحساب بنجاح!',
    'account_created_google': 'تم إنشاء الحساب عبر جوجل!',
    'google_signup_failed': 'فشل إنشاء الحساب عبر جوجل.',

    // Complete profile screen
    'complete_profile_title': 'أكمل ملفك الشخصي',
    'complete_profile_subtitle': 'بضع تفاصيل إضافية لتخصيص خطتك',
    'age': 'العمر',
    'weight': 'الوزن',
    'height': 'الطول (سم)',
    'goal': 'هدفك',
    'goal_lose_weight': 'خسارة الوزن',
    'goal_build_muscle': 'بناء العضلات',
    'goal_improve_fitness': 'تحسين اللياقة',
    'goal_maintain_weight': 'الحفاظ على الوزن',
    'kg': 'كجم',
    'lbs': 'رطل',
    'continue_label': 'متابعة',
    'saving': 'جارٍ الحفظ...',
    'invalid_age': 'يرجى إدخال عمر صحيح.',
    'invalid_weight': 'يرجى إدخال وزن صحيح.',
    'invalid_height': 'يرجى إدخال طول صحيح.',
    'please_select_goal': 'يرجى اختيار هدفك.',

    // Home placeholder
    'home_welcome_title': 'كل شيء جاهز!',
    'home_welcome_subtitle': 'لوحة التحكم الخاصة بك قادمة قريبًا.',
    'logout': 'تسجيل الخروج',
  };
}
