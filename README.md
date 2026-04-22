# Everwall - Plataforma de Cuadricula de Pixeles

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



