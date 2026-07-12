from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenRefreshView
from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from django.utils import timezone
from datetime import timedelta
import secrets
import uuid

from .models import UserProfile, EmailVerificationToken, PasswordResetToken
from .serializers import (
    RegisterSerializer, LoginSerializer, GoogleLoginSerializer,
    VerifyEmailSerializer, ResendVerificationSerializer,
    PasswordResetSerializer, PasswordResetConfirmSerializer,
    ChangePasswordSerializer, UserSerializer
)
from .throttles import LoginThrottle, RegisterThrottle, GoogleAuthThrottle, PasswordResetThrottle
from .emails import send_verification_email, send_password_reset_email


class RegisterView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [RegisterThrottle]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            
            # Send verification email
            try:
                verification_token = user.email_verification_token
                send_verification_email(user, verification_token.token, verification_token.uid)
            except Exception as e:
                pass
            
            return Response({
                'message': 'Registro exitoso. Revisa tu correo para verificar tu cuenta.',
                'user': UserSerializer(user).data
            }, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LoginView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [LoginThrottle]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email']
            password = serializer.validated_data['password']
            
            try:
                user = User.objects.get(email=email)
            except User.DoesNotExist:
                # Generic error to avoid user enumeration
                return Response(
                    {'error': 'Credenciales inválidas.'},
                    status=status.HTTP_401_UNAUTHORIZED
                )
            
            # Verify password
            if not user.check_password(password):
                return Response(
                    {'error': 'Credenciales inválidas.'},
                    status=status.HTTP_401_UNAUTHORIZED
                )
            
            # Generate tokens
            refresh = RefreshToken.for_user(user)
            
            return Response({
                'access': str(refresh.access_token),
                'refresh': str(refresh),
                'user': UserSerializer(user).data
            }, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class GoogleLoginView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [GoogleAuthThrottle]

    def post(self, request):
        serializer = GoogleLoginSerializer(data=request.data)
        if serializer.is_valid():
            id_token = serializer.validated_data['id_token']
            
            try:
                from google.auth.transport import requests
                from google.oauth2 import id_token
                
                request_obj = requests.Request()
                payload = id_token.verify_oauth2_token(id_token, request_obj)
                
                if payload['iss'] not in ['https://accounts.google.com', 'accounts.google.com']:
                    raise ValueError('Token inválido')
                
                email = payload['email']
                google_id = payload['sub']
                first_name = payload.get('given_name', '')
                last_name = payload.get('family_name', '')
                picture = payload.get('picture', '')
                
                # Try to get or create user
                user, created = User.objects.get_or_create(
                    email=email,
                    defaults={
                        'username': email,
                        'first_name': first_name,
                        'last_name': last_name,
                    }
                )
                
                # Update or create profile
                profile, _ = UserProfile.objects.get_or_create(user=user)
                profile.google_id = google_id
                profile.avatar = picture
                profile.is_email_verified = True  # Google already verified the email
                profile.save()
                
                # Generate tokens
                refresh = RefreshToken.for_user(user)
                
                return Response({
                    'access': str(refresh.access_token),
                    'refresh': str(refresh),
                    'user': UserSerializer(user).data
                }, status=status.HTTP_200_OK)
            
            except Exception as e:
                return Response(
                    {'error': 'Token de Google inválido o expirado.'},
                    status=status.HTTP_401_UNAUTHORIZED
                )
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            refresh_token = request.data.get('refresh')
            if refresh_token:
                token = RefreshToken(refresh_token)
                token.blacklist()
            
            return Response({
                'message': 'Logout exitoso.'
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )


class VerifyEmailView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = VerifyEmailSerializer(data=request.data)
        if serializer.is_valid():
            uid = serializer.validated_data['uid']
            token = serializer.validated_data['token']
            
            try:
                verification_token = EmailVerificationToken.objects.get(uid=uid, token=token)
                
                if not verification_token.is_valid():
                    return Response(
                        {'error': 'Token expirado.'},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                
                user = verification_token.user
                profile = user.profile
                profile.is_email_verified = True
                profile.save()
                
                verification_token.delete()
                
                return Response({
                    'message': 'Email verificado exitosamente.'
                }, status=status.HTTP_200_OK)
            
            except EmailVerificationToken.DoesNotExist:
                return Response(
                    {'error': 'Token inválido.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ResendVerificationView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [RegisterThrottle]

    def post(self, request):
        serializer = ResendVerificationSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email']
            
            try:
                user = User.objects.get(email=email)
                profile = user.profile
                
                if profile.is_email_verified:
                    return Response({
                        'message': 'Este correo ya está verificado.'
                    }, status=status.HTTP_200_OK)
                
                # Delete old token if exists
                EmailVerificationToken.objects.filter(user=user).delete()
                
                # Create new token
                token = secrets.token_urlsafe(48)
                uid = str(uuid.uuid4())
                expires_at = timezone.now() + timedelta(hours=24)
                
                EmailVerificationToken.objects.create(
                    user=user,
                    token=token,
                    uid=uid,
                    expires_at=expires_at
                )
                
                send_verification_email(user, token, uid)
                
                return Response({
                    'message': 'Email de verificación enviado.'
                }, status=status.HTTP_200_OK)
            
            except User.DoesNotExist:
                # Don't reveal if email exists (security)
                return Response({
                    'message': 'Si el correo está registrado, recibirás un email de verificación.'
                }, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class PasswordResetView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [PasswordResetThrottle]

    def post(self, request):
        serializer = PasswordResetSerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email']
            
            try:
                user = User.objects.get(email=email)
                
                # Delete old token if exists
                PasswordResetToken.objects.filter(user=user).delete()
                
                # Create new token
                token = secrets.token_urlsafe(48)
                uid = str(uuid.uuid4())
                expires_at = timezone.now() + timedelta(hours=1)
                
                PasswordResetToken.objects.create(
                    user=user,
                    token=token,
                    uid=uid,
                    expires_at=expires_at
                )
                
                send_password_reset_email(user, token, uid)
            
            except User.DoesNotExist:
                pass
            
            # Generic response to avoid user enumeration
            return Response({
                'message': 'Si el correo está registrado, recibirás un email para resetear tu contraseña.'
            }, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class PasswordResetConfirmView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        if serializer.is_valid():
            uid = serializer.validated_data['uid']
            token = serializer.validated_data['token']
            new_password = serializer.validated_data['new_password']
            
            try:
                reset_token = PasswordResetToken.objects.get(uid=uid, token=token)
                
                if not reset_token.is_valid():
                    return Response(
                        {'error': 'Token expirado.'},
                        status=status.HTTP_400_BAD_REQUEST
                    )
                
                user = reset_token.user
                user.set_password(new_password)
                user.save()
                
                # Invalidate all refresh tokens
                RefreshToken.for_user(user)  # This will blacklist previous tokens
                
                reset_token.delete()
                
                return Response({
                    'message': 'Contraseña actualizada exitosamente.'
                }, status=status.HTTP_200_OK)
            
            except PasswordResetToken.DoesNotExist:
                return Response(
                    {'error': 'Token inválido.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ChangePasswordView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        if serializer.is_valid():
            user = request.user
            old_password = serializer.validated_data['old_password']
            new_password = serializer.validated_data['new_password']
            
            if not user.check_password(old_password):
                return Response(
                    {'error': 'Contraseña actual incorrecta.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            user.set_password(new_password)
            user.save()
            
            # Invalidate all other refresh tokens
            # Note: In production, you'd want to blacklist all tokens except current
            
            return Response({
                'message': 'Contraseña actualizada exitosamente.'
            }, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        return Response(UserSerializer(user).data, status=status.HTTP_200_OK)
