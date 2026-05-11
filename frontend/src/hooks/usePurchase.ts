import { useState, useCallback } from 'react';
import { pixelService } from '../services/pixelService';
import { CreatePurchaseResponse } from '../types';

export const usePurchase = () => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [purchaseData, setPurchaseData] = useState<CreatePurchaseResponse | null>(null);

  const initiatePurchase = useCallback(async (data: {
    x: number;
    y: number;
    owner_email: string;
    owner_name: string;
    owner_message?: string;
    currency: 'USD' | 'CLP';
  }) => {
    setLoading(true);
    setError(null);

    try {
      const response = await pixelService.createPurchaseSession(data);
      setPurchaseData(response);
      return response;
    } catch (err: any) {
      setError(err.response?.data?.message || 'Error al iniciar la compra');
      return null;
    } finally {
      setLoading(false);
    }
  }, []);

  const confirmPurchase = useCallback(async (sessionId: string, paymentIntentId: string) => {
    setLoading(true);
    setError(null);

    try {
      const response = await pixelService.confirmPurchase(sessionId, paymentIntentId);
      setPurchaseData(null);
      return response.pixel;
    } catch (err: any) {
      setError(err.response?.data?.message || 'Error al confirmar la compra');
      return null;
    } finally {
      setLoading(false);
    }
  }, []);

  return {
    loading,
    error,
    purchaseData,
    initiatePurchase,
    confirmPurchase,
  };
};
