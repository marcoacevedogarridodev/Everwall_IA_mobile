from django.db import models
from django.contrib.auth.models import User
from django.core.mail import send_mail
from django.template.loader import render_to_string
from django.utils.html import strip_tags
from django.conf import settings
import uuid


class UserProfile(models.Model):
    """Perfil extendido del usuario"""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    google_id = models.CharField(max_length=255, blank=True, null=True, unique=True)
    avatar = models.URLField(blank=True, null=True)
    is_email_verified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Perfil de Usuario"
        verbose_name_plural = "Perfiles de Usuario"
        ordering = ['-created_at']

    def __str__(self):
        return f"Perfil de {self.user.email}"


class EmailVerificationToken(models.Model):
    """Token de un solo propósito para verificar email"""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='email_verification_token')
    token = models.CharField(max_length=64, unique=True)
    uid = models.CharField(max_length=64, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()

    class Meta:
        verbose_name = "Token de Verificación de Email"
        verbose_name_plural = "Tokens de Verificación de Email"

    def __str__(self):
        return f"Verificación para {self.user.email}"

    def is_valid(self):
        from django.utils import timezone
        return timezone.now() < self.expires_at


class PasswordResetToken(models.Model):
    """Token de un solo propósito para reset de contraseña"""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='password_reset_token')
    token = models.CharField(max_length=64, unique=True)
    uid = models.CharField(max_length=64, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()

    class Meta:
        verbose_name = "Token de Reset de Contraseña"
        verbose_name_plural = "Tokens de Reset de Contraseña"

    def __str__(self):
        return f"Reset para {self.user.email}"

    def is_valid(self):
        from django.utils import timezone
        return timezone.now() < self.expires_at
