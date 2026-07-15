### Instalacion
```bash
cd backend
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver

cd everwall-frontend
npm install
npx expo start

cd backend
docker-compose up --build

cd backend
.venv\Scripts\activate
pip install -r requirements.txt --break-system-packages

python manage.py test accounts

python manage.py test accounts --verbosity=2

# Resultado esperado:
# test_user_registration ✓
# test_user_login ✓
# test_login_with_wrong_password ✓
# test_get_current_user ✓
# test_protected_endpoint_without_token ✓
# test_user_profile_created ✓
# 
# Ra

GOOGLE_CLIENT_ID=client-id.apps.googleusercontent.com
FRONTEND_URL=http://localhost:3000
EMAIL_HOST_USER=email@gmail.com
EMAIL_HOST_PASSWORD=app-password

```

### API Endpoints

| Metodo | Endpoint | Descripcion |
|--------|----------|-------------|
| GET | `/api/pixels/` | Obtener todos los pixeles |
| GET | `/api/pixels/{id}/` | Obtener detalle de un pixel |
| POST | `/api/pixels/{id}/purchase/` | Comprar un pixel |
| PUT | `/api/pixels/{id}/content/` | Actualizar contenido de un pixel |
| GET | `/api/pixels/search/` | Buscar pixeles por propietario o contenido |
| POST | `/api/payments/webhook/` | Webhook para confirmacion de pagos |

### Registro
```bash
POST /api/auth/register/
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "password2": "SecurePass123!",
  "first_name": "Juan",
  "last_name": "Perez"
}
```
Se envia email de verificacion con link

### Login
```bash
POST /api/auth/login/
{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
→ Response: { access, refresh, user }
```

### Comprar Pixel (Autenticado)
```bash
1. POST /api/pixels/initiate_purchase/
   (multipart: x, y, images, owner_name, owner_message, currency)
   session_id

2. POST /api/pixels/create_payment_intent/
   (session_id, currency)
   client_secret para Stripe

3. POST /api/pixels/confirm_purchase/
   (payment_intent_id, session_id)
   Pixel creado con owner = request.user
```

### Ver Mis Pixeles
```bash
GET /api/pixels/my_pixels/
Authorization: Bearer <access_token>
Lista de pixeles que soy propietario
```

### Editar Mi Pixel
```bash
PUT /api/pixels/edit_pixel_content/
Authorization: Bearer <access_token>
{
  "x": 10,
  "y": 20,
  "owner_message": "Nuevo mensaje"
}
```