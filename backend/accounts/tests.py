from django.test import TestCase, Client
from django.contrib.auth.models import User
from django.urls import reverse
import json
from unittest.mock import patch


class AuthenticationTests(TestCase):
    
    def setUp(self):
        self.client = Client()
        self.register_url = '/api/auth/register/'
        self.login_url = '/api/auth/login/'
        self.me_url = '/api/auth/me/'
        self.logout_url = '/api/auth/logout/'
        
        self.test_user_data = {
            'email': 'test@example.com',
            'password': 'TestPass123!',
            'password2': 'TestPass123!',
            'first_name': 'Test',
            'last_name': 'User'
        }
    
    @patch('accounts.throttles.AnonRateThrottle.allow_request', return_value=True)
    def test_user_registration(self, mock_throttle):
        """Test that a user can register successfully"""
        response = self.client.post(
            self.register_url,
            json.dumps(self.test_user_data),
            content_type='application/json'
        )
        self.assertEqual(response.status_code, 201)
        self.assertIn('user', response.json())
        self.assertIn('email', response.json()['user'])
    
    @patch('accounts.throttles.AnonRateThrottle.allow_request', return_value=True)
    def test_user_login(self, mock_throttle):
        """Test that a registered user can login"""
        # First register
        self.client.post(
            self.register_url,
            json.dumps(self.test_user_data),
            content_type='application/json'
        )
        
        # Then login
        login_data = {
            'email': self.test_user_data['email'],
            'password': self.test_user_data['password']
        }
        response = self.client.post(
            self.login_url,
            json.dumps(login_data),
            content_type='application/json'
        )
        self.assertEqual(response.status_code, 200)
        self.assertIn('access', response.json())
        self.assertIn('refresh', response.json())
    
    @patch('accounts.throttles.AnonRateThrottle.allow_request', return_value=True)
    def test_login_with_wrong_password(self, mock_throttle):
        """Test that login with wrong password is rejected"""
        # First register
        self.client.post(
            self.register_url,
            json.dumps(self.test_user_data),
            content_type='application/json'
        )
        
        # Try to login with wrong password
        login_data = {
            'email': self.test_user_data['email'],
            'password': 'WrongPassword123!'
        }
        response = self.client.post(
            self.login_url,
            json.dumps(login_data),
            content_type='application/json'
        )
        self.assertEqual(response.status_code, 401)
        self.assertIn('error', response.json())
    
    @patch('accounts.throttles.AnonRateThrottle.allow_request', return_value=True)
    def test_get_current_user(self, mock_throttle):
        """Test getting current user info with token"""
        # Register and login
        self.client.post(
            self.register_url,
            json.dumps(self.test_user_data),
            content_type='application/json'
        )
        
        login_data = {
            'email': self.test_user_data['email'],
            'password': self.test_user_data['password']
        }
        login_response = self.client.post(
            self.login_url,
            json.dumps(login_data),
            content_type='application/json'
        )
        token = login_response.json()['access']
        
        # Get current user
        response = self.client.get(
            self.me_url,
            HTTP_AUTHORIZATION=f'Bearer {token}'
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()['email'], self.test_user_data['email'])
    
    def test_protected_endpoint_without_token(self):
        """Test that protected endpoints require authentication"""
        response = self.client.get(self.me_url)
        self.assertEqual(response.status_code, 401)
    
    @patch('accounts.throttles.AnonRateThrottle.allow_request', return_value=True)
    def test_user_profile_created(self, mock_throttle):
        """Test that UserProfile is created on registration"""
        self.client.post(
            self.register_url,
            json.dumps(self.test_user_data),
            content_type='application/json'
        )
        
        user = User.objects.get(email=self.test_user_data['email'])
        self.assertTrue(hasattr(user, 'profile'))
        self.assertFalse(user.profile.is_email_verified)
