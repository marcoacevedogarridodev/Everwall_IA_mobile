from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from .views import (
    RegisterView, LoginView, GoogleLoginView, LogoutView,
    VerifyEmailView, ResendVerificationView,
    PasswordResetView, PasswordResetConfirmView,
    ChangePasswordView, MeView
)

urlpatterns = [
    # Authentication
    path('auth/register/', RegisterView.as_view(), name='register'),
    path('auth/login/', LoginView.as_view(), name='login'),
    path('auth/google/', GoogleLoginView.as_view(), name='google_login'),
    path('auth/logout/', LogoutView.as_view(), name='logout'),
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('auth/me/', MeView.as_view(), name='me'),
    
    # Email verification
    path('auth/verify-email/', VerifyEmailView.as_view(), name='verify_email'),
    path('auth/resend-verification/', ResendVerificationView.as_view(), name='resend_verification'),
    
    # Password reset
    path('auth/password-reset/', PasswordResetView.as_view(), name='password_reset'),
    path('auth/password-reset/confirm/', PasswordResetConfirmView.as_view(), name='password_reset_confirm'),
    path('auth/change-password/', ChangePasswordView.as_view(), name='change_password'),
]
