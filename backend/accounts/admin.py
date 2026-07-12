from django.contrib import admin
from django.contrib.auth.models import User
from .models import UserProfile, EmailVerificationToken, PasswordResetToken


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ['user_email', 'is_email_verified', 'google_id', 'created_at']
    list_filter = ['is_email_verified', 'created_at']
    search_fields = ['user__email', 'google_id']
    readonly_fields = ['created_at', 'updated_at']

    def user_email(self, obj):
        return obj.user.email
    user_email.short_description = 'Email'


@admin.register(EmailVerificationToken)
class EmailVerificationTokenAdmin(admin.ModelAdmin):
    list_display = ['user_email', 'is_valid', 'created_at', 'expires_at']
    list_filter = ['created_at']
    search_fields = ['user__email']
    readonly_fields = ['created_at', 'token', 'uid']

    def user_email(self, obj):
        return obj.user.email
    user_email.short_description = 'Email'


@admin.register(PasswordResetToken)
class PasswordResetTokenAdmin(admin.ModelAdmin):
    list_display = ['user_email', 'is_valid', 'created_at', 'expires_at']
    list_filter = ['created_at']
    search_fields = ['user__email']
    readonly_fields = ['created_at', 'token', 'uid']

    def user_email(self, obj):
        return obj.user.email
    user_email.short_description = 'Email'
