#!/usr/bin/env python
import os
import sys
import django
from django.test import Client
from django.contrib.auth.models import User
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'app.settings')
django.setup()
from accounts.models import UserProfile

client = Client()

print("=" * 60)
print("Testing JWT Authentication System")
print("=" * 60)

print("\n1. Testing Registration...")
response = client.post('/api/auth/register/', {
    'email': 'test@example.com',
    'password': 'TestPass123!',
    'password2': 'TestPass123!',
    'first_name': 'Test',
    'last_name': 'User'
}, content_type='application/json')

if response.status_code == 201:
    print(" Registration successful (201)")
    data = response.json()
    print(f"   User created: {data['user']['email']}")
else:
    print(f" Registration failed ({response.status_code})")
    print(f"   {response.json()}")

print("\n2. Testing Login...")
response = client.post('/api/auth/login/', {
    'email': 'test@example.com',
    'password': 'TestPass123!'
}, content_type='application/json')

if response.status_code == 200:
    print(" Login successful (200)")
    data = response.json()
    access_token = data.get('access')
    refresh_token = data.get('refresh')
    print(f"   Access token: {access_token[:30]}...")
    print(f"   Refresh token: {refresh_token[:30]}...")
else:
    print(f" Login failed ({response.status_code})")
    print(f"   {response.json()}")
    sys.exit(1)

print("\n3. Testing Get Current User (me)...")
response = client.get('/api/auth/me/', HTTP_AUTHORIZATION=f'Bearer {access_token}')

if response.status_code == 200:
    print(" Get current user successful (200)")
    data = response.json()
    print(f"   Email: {data['email']}")
    print(f"   Name: {data['first_name']} {data['last_name']}")
else:
    print(f" Get current user failed ({response.status_code})")
    print(f"   {response.json()}")

print("\n4. Testing Login with Wrong Password...")
response = client.post('/api/auth/login/', {
    'email': 'test@example.com',
    'password': 'WrongPassword'
}, content_type='application/json')

if response.status_code == 401:
    print(" Wrong password rejected (401)")
else:
    print(f" Should have rejected wrong password, got {response.status_code}")

print("\n5. Testing Protected Endpoint without Token...")
response = client.get('/api/auth/me/')

if response.status_code == 401:
    print(" Protected endpoint correctly rejected (401)")
else:
    print(f" Should require authentication, got {response.status_code}")

print("\n6. Testing Change Password...")
response = client.post('/api/auth/change-password/', {
    'old_password': 'TestPass123!',
    'new_password': 'NewPass456!@',
    'new_password2': 'NewPass456!@'
}, HTTP_AUTHORIZATION=f'Bearer {access_token}', content_type='application/json')

if response.status_code == 200:
    print("Change password successful (200)")
else:
    print(f"Change password failed ({response.status_code})")
    print(f"   {response.json()}")

print("\n7. Testing Logout...")
response = client.post('/api/auth/logout/', {
    'refresh': refresh_token
}, HTTP_AUTHORIZATION=f'Bearer {access_token}', content_type='application/json')

if response.status_code == 200:
    print("Logout successful (200)")
else:
    print(f"Logout failed ({response.status_code})")

print("\n8. Verifying UserProfile was Created...")
try:
    user = User.objects.get(email='test@example.com')
    profile = user.profile
    if profile and profile.is_email_verified == False:
        print("    UserProfile created successfully")
        print(f"   Email verified: {profile.is_email_verified}")
        print(f"   Google ID: {profile.google_id}")
    else:
        print(" UserProfile not properly configured")
except Exception as e:
    print(f" Error: {e}")

print("\n" + "=" * 60)
print("All tests completed!")
print("=" * 60)
