import React, { useState, useCallback, useMemo } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Dimensions,
  TouchableOpacity,
  Image,
  Modal,
  ScrollView,
} from 'react-native';
import { GestureDetector, Gesture } from 'react-native-gesture-handler';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
} from 'react-native-reanimated';
import { Pixel, GridStatus } from '../types';
import { COLORS } from '../utils/constants';
import { ShareButtons } from './ShareButtons';

const { width: SCREEN_WIDTH, height: SCREEN_HEIGHT } = Dimensions.get('window');

interface PixelGridProps {
  gridStatus: GridStatus;
  pixels: Pixel[];
  onPixelPress: (pixel: Pixel) => void;
  onEmptyPixelPress: (x: number, y: number) => void;
  selectedPixel: Pixel | null;
  onCloseModal: () => void;
}

export const PixelGrid: React.FC<PixelGridProps> = ({
  gridStatus,
  pixels,
  onPixelPress,
  onEmptyPixelPress,
  selectedPixel,
  onCloseModal,
}) => {
  const [containerSize, setContainerSize] = useState({ width: 0, height: 0 });

  // Valores de zoom y pan
  const scale = useSharedValue(1);
  const savedScale = useSharedValue(1);
  const translateX = useSharedValue(0);
  const translateY = useSharedValue(0);
  const savedTranslateX = useSharedValue(0);
  const savedTranslateY = useSharedValue(0);

  // Mapa de pixeles para acceso rápido
  const pixelMap = useMemo(() => {
    const map = new Map<string, Pixel>();
    pixels.forEach(pixel => {
      if (pixel.status === 'sold' && pixel.moderation_status === 'approved') {
        map.set(`${pixel.x},${pixel.y}`, pixel);
      }
    });
    return map;
  }, [pixels]);

  // Calcular tamaño de cada pixel
  const pixelSize = useMemo(() => {
    const sizeX = containerSize.width / gridStatus.grid_width;
    const sizeY = containerSize.height / gridStatus.grid_height;
    return Math.min(sizeX, sizeY);
  }, [containerSize, gridStatus]);

  // Gestos de zoom y pan
  const pinchGesture = Gesture.Pinch()
    .onUpdate((event) => {
      scale.value = savedScale.value * event.scale;
    })
    .onEnd(() => {
      savedScale.value = scale.value;
    });

  const panGesture = Gesture.Pan()
    .onUpdate((event) => {
      translateX.value = savedTranslateX.value + event.translationX;
      translateY.value = savedTranslateY.value + event.translationY;
    })
    .onEnd(() => {
      savedTranslateX.value = translateX.value;
      savedTranslateY.value = translateY.value;
    });

  const composedGestures = Gesture.Simultaneous(pinchGesture, panGesture);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [
      { translateX: translateX.value },
      { translateY: translateY.value },
      { scale: scale.value },
    ],
  }));

  const renderPixel = useCallback((x: number, y: number) => {
    const key = `${x},${y}`;
    const pixel = pixelMap.get(key);
    const isSelected = selectedPixel?.x === x && selectedPixel?.y === y;

    return (
      <TouchableOpacity
        key={key}
        style={[
          styles.pixel,
          {
            width: pixelSize,
            height: pixelSize,
            left: x * pixelSize,
            top: y * pixelSize,
            borderColor: isSelected ? COLORS.primary : COLORS.border,
          },
        ]}
        onPress={() => {
          if (pixel) {
            onPixelPress(pixel);
          } else {
            onEmptyPixelPress(x, y);
          }
        }}
        activeOpacity={0.8}
      >
        {pixel?.main_image ? (
          <Image
            source={{ uri: pixel.main_image }}
            style={styles.pixelImage}
            resizeMode="cover"
          />
        ) : (
          <View style={styles.emptyPixel}>
            <Text style={styles.emptyPixelText}>+</Text>
          </View>
        )}
      </TouchableOpacity>
    );
  }, [pixelSize, pixelMap, selectedPixel, onPixelPress, onEmptyPixelPress]);

  const renderGrid = useMemo(() => {
    const pixels = [];
    for (let y = 0; y < gridStatus.grid_height; y++) {
      for (let x = 0; x < gridStatus.grid_width; x++) {
        pixels.push(renderPixel(x, y));
      }
    }
    return pixels;
  }, [gridStatus.grid_width, gridStatus.grid_height, renderPixel]);

  return (
    <View style={styles.container}>
      <View
        style={styles.gridContainer}
        onLayout={(e) => {
          const { width, height } = e.nativeEvent.layout;
          setContainerSize({ width, height });
        }}
      >
        <GestureDetector gesture={composedGestures}>
          <Animated.View
            style={[
              styles.grid,
              {
                width: gridStatus.grid_width * pixelSize,
                height: gridStatus.grid_height * pixelSize,
              },
              animatedStyle,
            ]}
          >
            {containerSize.width > 0 && renderGrid}
          </Animated.View>
        </GestureDetector>
      </View>

      {/* Modal de detalle del pixel */}
      <Modal
        visible={!!selectedPixel}
        animationType="slide"
        transparent={true}
        onRequestClose={onCloseModal}
      >
        <View style={styles.modalContainer}>
          <View style={styles.modalContent}>
            <TouchableOpacity style={styles.closeButton} onPress={onCloseModal}>
              <Text style={styles.closeButtonText}>✕</Text>
            </TouchableOpacity>

            <ScrollView showsVerticalScrollIndicator={false}>
              {selectedPixel?.main_image && (
                <Image
                  source={{ uri: selectedPixel.main_image }}
                  style={styles.modalImage}
                  resizeMode="contain"
                />
              )}

              <View style={styles.modalInfo}>
                <Text style={styles.modalCode}>{selectedPixel?.display_code}</Text>

                {selectedPixel?.owner_name && (
                  <Text style={styles.modalOwner}>Por: {selectedPixel.owner_name}</Text>
                )}

                {selectedPixel?.owner_message && (
                  <Text style={styles.modalMessage}>"{selectedPixel.owner_message}"</Text>
                )}

                <View style={styles.statsContainer}>
                  <Text style={styles.statsText}>
                    👁️ {selectedPixel?.views_count || 0} visualizaciones
                  </Text>
                  <Text style={styles.statsText}>
                    📍 Posición: ({selectedPixel?.x}, {selectedPixel?.y})
                  </Text>
                </View>

                {selectedPixel && (
                  <ShareButtons pixel={selectedPixel} />
                )}
              </View>
            </ScrollView>
          </View>
        </View>
      </Modal>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.background,
  },
  gridContainer: {
    flex: 1,
    backgroundColor: COLORS.background,
    overflow: 'hidden',
  },
  grid: {
    position: 'relative',
    backgroundColor: COLORS.surface,
  },
  pixel: {
    position: 'absolute',
    borderWidth: 0.5,
    borderColor: COLORS.border,
    overflow: 'hidden',
  },
  pixelImage: {
    width: '100%',
    height: '100%',
  },
  emptyPixel: {
    flex: 1,
    backgroundColor: COLORS.surface,
    justifyContent: 'center',
    alignItems: 'center',
  },
  emptyPixelText: {
    color: COLORS.textSecondary,
    fontSize: 12,
    opacity: 0.3,
  },
  modalContainer: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.9)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalContent: {
    width: SCREEN_WIDTH * 0.9,
    maxHeight: SCREEN_HEIGHT * 0.8,
    backgroundColor: COLORS.surface,
    borderRadius: 16,
    padding: 20,
  },
  closeButton: {
    position: 'absolute',
    top: 10,
    right: 10,
    zIndex: 1,
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  closeButtonText: {
    color: COLORS.text,
    fontSize: 20,
    fontWeight: 'bold',
  },
  modalImage: {
    width: '100%',
    height: 300,
    borderRadius: 8,
    marginBottom: 16,
  },
  modalInfo: {
    paddingHorizontal: 4,
  },
  modalCode: {
    color: COLORS.primary,
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 8,
  },
  modalOwner: {
    color: COLORS.text,
    fontSize: 16,
    marginBottom: 8,
  },
  modalMessage: {
    color: COLORS.textSecondary,
    fontSize: 14,
    fontStyle: 'italic',
    marginBottom: 16,
  },
  statsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginBottom: 20,
    paddingVertical: 12,
    borderTopWidth: 1,
    borderBottomWidth: 1,
    borderColor: COLORS.border,
  },
  statsText: {
    color: COLORS.text,
    fontSize: 14,
  },
});
