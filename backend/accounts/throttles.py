from rest_framework.throttling import UserRateThrottle, AnonRateThrottle


class LoginThrottle(AnonRateThrottle):
    """5 intentos de login por minuto por IP"""
    scope = 'login'
    rate = '5/min'


class RegisterThrottle(AnonRateThrottle):
    """3 registros por minuto por IP"""
    scope = 'register'
    rate = '3/min'


class GoogleAuthThrottle(AnonRateThrottle):
    """3 intentos de Google Auth por minuto por IP"""
    scope = 'google_auth'
    rate = '3/min'


class PasswordResetThrottle(AnonRateThrottle):
    """5 reset de contraseña por minuto por IP"""
    scope = 'password_reset'
    rate = '5/min'
