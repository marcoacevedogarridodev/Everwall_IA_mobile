import { useState, useCallback } from 'react';
import { pixelService } from '../services/pixelService';
import { Pixel } from '../types';

export const usePixelSearch = () => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [pixel, setPixel] = useState<Pixel | null>(null);

  const searchPixel = useCallback(async (code: string) => {
    if (!code.trim()) {
      setError('Ingresa un código válido');
      return null;
    }

    setLoading(true);
    setError(null);

    try {
      const response = await pixelService.searchPixel(code);
      if (response.found && response.pixel) {
        setPixel(response.pixel);
        return response.pixel;
      } else {
        setError(response.message || 'Pixel no encontrado');
        setPixel(null);
        return null;
      }
    } catch (err: any) {
      setError(err.response?.data?.message || 'Error al buscar el pixel');
      setPixel(null);
      return null;
    } finally {
      setLoading(false);
    }
  }, []);

  const clearSearch = useCallback(() => {
    setPixel(null);
    setError(null);
  }, []);

  return {
    loading,
    error,
    pixel,
    searchPixel,
    clearSearch,
  };
};
