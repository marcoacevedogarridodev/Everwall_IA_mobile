// URL base de la API (cambiar según tu entorno)
export const API_BASE_URL = 'http://192.168.1.100:8000/api'; // Cambia por tu IP local

// Colores de la aplicación
export const COLORS = {
  primary: '#549cfe', // Color ballena DeepSeek
  background: '#000000',
  surface: '#1a1a1a',
  text: '#ffffff',
  textSecondary: '#888888',
  border: '#333333',
  success: '#4CAF50',
  error: '#f44336',
  warning: '#ff9800',
};

// Configuración de la grilla
export const GRID_CONFIG = {
  MIN_ZOOM: 0.5,
  MAX_ZOOM: 5,
  INITIAL_ZOOM: 1,
  DOUBLE_TAP_ZOOM: 2,
};

// Endpoints de la API
export const ENDPOINTS = {
  GRID_STATUS: '/pixels/grid_status/',
  STATS: '/pixels/stats/',
  RECENT_PIXELS: '/pixels/recent_pixels/',
  SEARCH_PIXEL: '/pixels/search_pixel/',
  CREATE_PURCHASE: '/pixels/create_purchase/',
  CONFIRM_PURCHASE: '/pixels/confirm_purchase/',
  UPLOAD_IMAGE: '/pixels/upload_image/',
  GET_PIXEL: (code: string) => `/pixels/detail/${code}/`,
  INCREMENT_VIEW: (code: string) => `/pixels/${code}/increment_view/`,
};

// Mensajes de la aplicación
export const MESSAGES = {
  WELCOME_TITLE: 'EverWall',
  WELCOME_SUBTITLE: 'Tu imagen en la pared digital más grande del mundo',
  CTA_MAIN: '¡Sube tu imagen ahora!',
  GRID_TITLE: 'El Muro',
  UPLOAD_BUTTON: 'Subir imagen',
  SEARCH_PLACEHOLDER: 'Buscar por código (#12345)',
  PURCHASE_TITLE: 'Reserva tu pixel',
  PURCHASE_SUBTITLE: 'Completa tus datos y sube tu imagen',
};
