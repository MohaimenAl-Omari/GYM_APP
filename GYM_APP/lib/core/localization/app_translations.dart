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

    // Home dashboard
    'home_hi': 'Hi',
    'home_ready_subtitle': "Ready to crush today's workout?",
    'home_this_week': 'This Week',
    'home_stat_workouts': 'Workouts',
    'home_stat_minutes': 'Minutes',
    'home_stat_streak': 'Day Streak',
    'home_start_workout': 'Start Workout',
    'home_start_workout_subtitle': 'Begin a new training session',
    'home_quick_actions': 'Quick Actions',
    'home_exercises': 'Exercises',
    'home_progress': 'Progress',
    'home_history': 'History',
    'home_profile': 'Profile',
    'home_coming_soon': 'Coming soon',
    'logout': 'Logout',

    // Exercise library
    'exercises_empty': 'No exercises here yet.',
    'search_exercises': 'Search exercises...',
    'last_performance': 'Last Performance',
    'last_time_on': 'Last time on',
    'no_history_yet': "You haven't logged this exercise yet.",
    'set_label': 'Set',
    'reps_label': 'reps',
    'generic_error': 'Something went wrong. Please try again.',
    'retry': 'Retry',

    // Start workout
    'choose_muscle_groups': 'Choose muscle groups',
    'choose_exercises': 'Choose exercises',

    // Active workout logging
    'last_time': 'Last time',
    'confirm_set': 'Confirm Set',
    'resting': 'Resting',
    'skip': 'Skip',
    'exercise_progress': 'Exercise',
    'finish_workout': 'Finish',
    'leave_workout_title': 'Leave this workout?',
    'leave_workout_message':
        "Your logged sets are already saved, but you'll end the session early.",
    'cancel': 'Cancel',
    'leave': 'Leave',
    'save': 'Save',

    // Workout summary
    'workout_complete': 'Workout Complete',
    'workout_complete_subtitle': 'Nice work — logged and saved.',
    'total_sets': 'Sets',
    'total_volume': 'Volume',
    'done': 'Done',
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

    // Home dashboard
    'home_hi': 'مرحباً',
    'home_ready_subtitle': 'هل أنت مستعد لتمرين اليوم؟',
    'home_this_week': 'هذا الأسبوع',
    'home_stat_workouts': 'تمارين',
    'home_stat_minutes': 'دقيقة',
    'home_stat_streak': 'يوم متتالي',
    'home_start_workout': 'ابدأ التمرين',
    'home_start_workout_subtitle': 'ابدأ جلسة تدريب جديدة',
    'home_quick_actions': 'إجراءات سريعة',
    'home_exercises': 'التمارين',
    'home_progress': 'التقدم',
    'home_history': 'السجل',
    'home_profile': 'الملف الشخصي',
    'home_coming_soon': 'قريباً',
    'logout': 'تسجيل الخروج',

    // Exercise library
    'exercises_empty': 'لا توجد تمارين هنا بعد.',
    'search_exercises': 'ابحث عن تمارين...',
    'last_performance': 'آخر أداء',
    'last_time_on': 'آخر مرة بتاريخ',
    'no_history_yet': 'لم تسجّل هذا التمرين بعد.',
    'set_label': 'مجموعة',
    'reps_label': 'تكرار',
    'generic_error': 'حدث خطأ ما. حاول مرة أخرى.',
    'retry': 'إعادة المحاولة',

    // Start workout
    'choose_muscle_groups': 'اختر المجموعات العضلية',
    'choose_exercises': 'اختر التمارين',

    // Active workout logging
    'last_time': 'آخر مرة',
    'confirm_set': 'تأكيد المجموعة',
    'resting': 'راحة',
    'skip': 'تخطي',
    'exercise_progress': 'تمرين',
    'finish_workout': 'إنهاء',
    'leave_workout_title': 'مغادرة التمرين؟',
    'leave_workout_message': 'المجموعات اللي سجّلتها محفوظة، بس رح تنهي الجلسة بدري.',
    'cancel': 'إلغاء',
    'leave': 'مغادرة',
    'save': 'حفظ',

    // Workout summary
    'workout_complete': 'اكتمل التمرين',
    'workout_complete_subtitle': 'أداء رائع — تم الحفظ.',
    'total_sets': 'المجموعات',
    'total_volume': 'الحجم',
    'done': 'تم',
  };
}
