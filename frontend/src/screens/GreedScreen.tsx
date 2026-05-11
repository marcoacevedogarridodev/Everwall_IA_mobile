import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  TouchableOpacity,
  TextInput,
  Alert,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { PixelGrid } from '../components/PixelGrid';
import { PaymentModal } from '../components/PaymentModal';
import { LoadingSpinner } from '../components/LoadingSpinner';
import { pixelService } from '../services/pixelService';
import { usePixelSearch } from '../hooks/usePixelSearch';
import { GridStatus, Pixel } from '../types';
import { COLORS } from '../utils/constants';

export const GridScreen: React.FC = () => {
  const navigation = useNavigation();
  const { searchPixel, pixel: searchedPixel, loading: searchLoading } = usePixelSearch();

  const [loading, setLoading] = useState(true);
  const [gridStatus, setGridStatus] = useState<GridStatus | null>(null);
  const [pixels, setPixels] = useState<Pixel[]>([]);
  const [selectedPixel, setSelectedPixel] = useState<Pixel | null>(null);
  const [showPaymentModal, setShowPaymentModal] = useState(false);
  const [selectedPosition, setSelectedPosition] = useState<{ x: number; y: number } | null>(null);
  const [searchCode, setSearchCode] = useState('');

  useEffect(() => {
    loadGridData();
  }, []);

  const loadGridData = async () => {
    try {
      setLoading(true);
      const [status, recentPixels] = await Promise.all([
        pixelService.getGridStatus(),
        pixelService.getRecentPixels(100),
      ]);
      setGridStatus(status);
      setPixels(recentPixels);
    } catch (error) {
      console.error('Error loading grid:', error);
      Alert.alert('Error', 'No se pudo cargar la grilla');
    } finally {
      setLoading(false);
    }
  };

  const handlePixelPress = useCallback(async (pixel: Pixel) => {
    setSelectedPixel(pixel);
    await pixelService.incrementView(pixel.search_code);
    // Recargar para actualizar contador de vistas
    loadGridData();
  }, []);

  const handleEmptyPixelPress = useCallback((x: number, y: number) => {
    setSelectedPosition({ x, y });
    setShowPaymentModal(true);
  }, []);

  const handleCloseModal = useCallback(() => {
    setSelectedPixel(null);
  }, []);

  const handleSearch = async () => {
    if (!searchCode.trim()) {
      Alert.alert('Error', 'Ingresa un código para buscar');
      return;
    }

    const pixel = await searchPixel(searchCode);
    if (pixel) {
      setSelectedPixel(pixel);
      setSearchCode('');
    } else {
      Alert.alert('No encontrado', 'No se encontró ningún pixel con ese código');
    }
  };

  const handlePaymentSuccess = async (pixel: Pixel) => {
    setShowPaymentModal(false);
    await loadGridData();
    setSelectedPixel(pixel);
  };

  if (loading || !gridStatus) {
    return <LoadingSpinner message="Cargando el muro..." />;
  }

  return (
    <SafeAreaView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <Text style={styles.backButton}>← Volver</Text>
        </TouchableOpacity>

        <View style={styles.searchContainer}>
          <TextInput
            style={styles.searchInput}
            placeholder="Buscar código..."
            placeholderTextColor={COLORS.textSecondary}
            value={searchCode}
            onChangeText={setSearchCode}
            onSubmitEditing={handleSearch}
            autoCapitalize="characters"
          />
          <TouchableOpacity style={styles.searchButton} onPress={handleSearch}>
            <Text style={styles.searchButtonText}>🔍</Text>
          </TouchableOpacity>
        </View>

        <TouchableOpacity
          style={styles.uploadButton}
          onPress={() => {
            // Buscar primer pixel disponible o permitir selección
            Alert.alert(
              'Subir imagen',
              'Selecciona un pixel disponible en la grilla para comenzar',
              [{ text: 'OK' }]
            );
          }}
        >
          <Text style={styles.uploadButtonText}>Subir imagen</Text>
        </TouchableOpacity>
      </View>

      {/* Estadísticas rápidas */}
      <View style={styles.statsBar}>
        <Text style={styles.statsText}>
          {gridStatus.sold_pixels} / {gridStatus.total_pixels} pixeles vendidos
        </Text>
        <Text style={styles.statsText}>
          ${gridStatus.pixel_price_usd} USD / ${gridStatus.pixel_price_clp.toLocaleString()} CLP
        </Text>
      </View>

      {/* Grilla */}
      <PixelGrid
        gridStatus={gridStatus}
        pixels={pixels}
        onPixelPress={handlePixelPress}
        onEmptyPixelPress={handleEmptyPixelPress}
        selectedPixel={selectedPixel}
        onCloseModal={handleCloseModal}
      />

      {/* Modal de pago */}
      {selectedPosition && (
        <PaymentModal
          visible={showPaymentModal}
          onClose={() => setShowPaymentModal(false)}
          pixelX={selectedPosition.x}
          pixelY={selectedPosition.y}
          priceUSD={gridStatus.pixel_price_usd}
          priceCLP={gridStatus.pixel_price_clp}
          onSuccess={handlePaymentSuccess}
        />
      )}
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: COLORS.border,
  },
  backButton: {
    color: COLORS.primary,
    fontSize: 16,
  },
  searchContainer: {
    flex: 1,
    flexDirection: 'row',
    marginHorizontal: 12,
  },
  searchInput: {
    flex: 1,
    backgroundColor: COLORS.surface,
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
    color: COLORS.text,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  searchButton: {
    paddingHorizontal: 12,
    justifyContent: 'center',
    alignItems: 'center',
  },
  searchButtonText: {
    fontSize: 20,
  },
  uploadButton: {
    backgroundColor: COLORS.primary,
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 8,
  },
  uploadButtonText: {
    color: COLORS.text,
    fontSize: 14,
    fontWeight: 'bold',
  },
  statsBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 8,
    backgroundColor: COLORS.surface,
    borderBottomWidth: 1,
    borderBottomColor: COLORS.border,
  },
  statsText: {
    color: COLORS.textSecondary,
    fontSize: 12,
  },
});
