# Everwall - Plataforma de Cuadrícula de Píxeles

## Estructura del Proyecto

backend/
│
├── app/
│ ├── init.py
│ ├── asgi.py
│ ├── settings.py
│ ├── urls.py
│ └── wsgi.py
│
├── server/
│ ├── migrations/
│ ├── init.py
│ ├── admin.py
│ ├── apps.py
│ ├── models.py
│ ├── tests.py
│ ├── views.py
│ ├── urls.py
│ ├── serializers.py
│ └── services/
│ ├── init.py
│ ├── moderation.py
│ ├── payment.py
│ └── grid_manager.py
│
├── static/
├── media/
├── db.sqlite3
├── .dockerignore
├── docker-compose.yml
├── Dockerfile
├── requirements.txt
└── manage.py

everwall-frontend/
├── src/
│ ├── screens/
│ │ ├── GridScreen.tsx
│ │ ├── PurchaseScreen.tsx
│ │ ├── SearchScreen.tsx
│ │ ├── PixelDetailScreen.tsx
│ │ └── ProfileScreen.tsx
│ ├── components/
│ │ ├── PixelGrid.tsx
│ │ ├── ImageUploader.tsx
│ │ ├── PaymentModal.tsx
│ │ ├── ShareButtons.tsx
│ │ └── LoadingSpinner.tsx
│ ├── services/
│ │ ├── api.ts
│ │ ├── pixelService.ts
│ │ └── paymentService.ts
│ ├── hooks/
│ │ ├── usePixelSearch.ts
│ │ └── usePurchase.ts
│ ├── utils/
│ │ ├── constants.ts
│ │ └── helpers.ts
│ ├── types/
│ │ └── index.ts
│ └── App.tsx
├── public/
├── package.json
├── app.json
└── tsconfig.json


## Tecnologias Utilizadas

| Capa | Tecnologias |
|------|-------------|
| **Backend** | Django, Django REST Framework, SQLite, Docker, Docker Compose |
| **Frontend** | React Native, Expo, TypeScript, Axios |
| **Pagos** | Integración con pasarela de pagos |
| **Moderación** | Servicio de moderación de contenido |

## API Endpoints

| Metodo | Endpoint | Descripcion |
|--------|----------|-------------|
| GET | `/api/pixels/` | Obtener todos los pixeles |
| GET | `/api/pixels/{id}/` | Obtener detalle de un pixel |
| POST | `/api/pixels/{id}/purchase/` | Comprar un pixel |
| PUT | `/api/pixels/{id}/content/` | Actualizar contenido de un pixel |
| GET | `/api/pixels/search/` | Buscar pixeles por propietario o contenido |
| POST | `/api/payments/webhook/` | Webhook para confirmación de pagos |

## Instalacion Rapida

### Backend (Django)
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



