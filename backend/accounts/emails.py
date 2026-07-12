from django.core.mail import send_mail
from django.template.loader import render_to_string
from django.utils.html import strip_tags
from django.conf import settings


def send_verification_email(user, token, uid):
    """Envía email de verificación"""
    verification_link = f"{settings.FRONTEND_URL}/verify-email?uid={uid}&token={token}"
    
    context = {
        'user_name': user.first_name or user.email,
        'verification_link': verification_link,
    }
    
    html_message = render_to_string('emails/verify_email.html', context)
    plain_message = strip_tags(html_message)
    
    send_mail(
        subject='Verifica tu correo - Everwall',
        message=plain_message,
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=[user.email],
        html_message=html_message,
        fail_silently=False,
    )


def send_password_reset_email(user, token, uid):
    """Envía email de reset de contraseña"""
    reset_link = f"{settings.FRONTEND_URL}/reset-password?uid={uid}&token={token}"
    
    context = {
        'user_name': user.first_name or user.email,
        'reset_link': reset_link,
    }
    
    html_message = render_to_string('emails/reset_password.html', context)
    plain_message = strip_tags(html_message)
    
    send_mail(
        subject='Reset tu contraseña - Everwall',
        message=plain_message,
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=[user.email],
        html_message=html_message,
        fail_silently=False,
    )
