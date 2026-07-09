import api from './api';
import { ENDPOINTS } from '../utils/constants';
import {
  GridStatus,
  GridStats,
  Pixel,
  SearchPixelResponse,
  CreatePurchaseResponse
} from '../types';

export const pixelService = {
  // Obtener estado de la grilla
  async getGridStatus(): Promise<GridStatus> {
    const response = await api.get(ENDPOINTS.GRID_STATUS);
    return response.data;
  },

  // Obtener estadísticas generales
  async getStats(): Promise<GridStats> {
    const response = await api.get(ENDPOINTS.STATS);
    return response.data;
  },

  // Obtener pixeles recientes
  async getRecentPixels(limit: number = 20): Promise<Pixel[]> {
    const response = await api.get(`${ENDPOINTS.RECENT_PIXELS}?limit=${limit}`);
    return response.data;
  },

  // Buscar pixel por código
  async searchPixel(code: string): Promise<SearchPixelResponse> {
    const response = await api.post(ENDPOINTS.SEARCH_PIXEL, { code });
    return response.data;
  },

  // Obtener detalle del pixel
  async getPixelDetail(code: string): Promise<Pixel> {
    const response = await api.get(ENDPOINTS.GET_PIXEL(code));
    return response.data;
  },

  // Incrementar vistas
  async incrementView(code: string): Promise<void> {
    await api.post(ENDPOINTS.INCREMENT_VIEW(code));
  },

  // Crear sesión de compra
  async createPurchaseSession(data: {
    x: number;
    y: number;
    owner_email: string;
    owner_name: string;
    owner_message?: string;
    currency: 'USD' | 'CLP';
  }): Promise<CreatePurchaseResponse> {
    const response = await api.post(ENDPOINTS.CREATE_PURCHASE, data);
    return response.data;
  },

  // Subir imagen para pixel
  async uploadPixelImage(formData: FormData): Promise<{ url: string }> {
    const response = await api.post(ENDPOINTS.UPLOAD_IMAGE, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
    return response.data;
  },

  // Confirmar compra
  async confirmPurchase(sessionId: string, paymentIntentId: string): Promise<{ pixel: Pixel }> {
    const response = await api.post(ENDPOINTS.CONFIRM_PURCHASE, {
      session_id: sessionId,
      payment_intent_id: paymentIntentId,
    });
    return response.data;
  },
};
