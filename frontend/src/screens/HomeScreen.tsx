import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  TouchableOpacity,
  Image,
  Dimensions,
  Animated,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { LinearGradient } from 'expo-linear-gradient';
import { pixelService } from '../services/pixelService';
import { COLORS } from '../utils/constants';

const { width } = Dimensions.get('window');

export const HomeScreen: React.FC = () => {
  const navigation = useNavigation();
  const [stats, setStats] = useState({
    totalPixels: 0,
    soldPixels: 0,
    totalViews: 0,
  });

  // Animación para la flecha
  const arrowAnimation = new Animated.Value(0);

  // Animación para los contadores
  const [animatedSold, setAnimatedSold] = useState(0);
  const [animatedViews, setAnimatedViews] = useState(0);

  useEffect(() => {
    loadStats();
    startArrowAnimation();

    // Actualizar stats cada 30 segundos
    const interval = setInterval(loadStats, 30000);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    if (stats.soldPixels > 0) {
      animateNumber(stats.soldPixels, setAnimatedSold);
    }
    if (stats.totalViews > 0) {
      animateNumber(stats.totalViews, setAnimatedViews);
    }
  }, [stats]);

  const loadStats = async () => {
    try {
      const data = await pixelService.getStats();
      setStats({
        totalPixels: data.total_pixels,
        soldPixels: data.sold_pixels,
        totalViews: data.total_views,
      });
    } catch (error) {
      console.error('Error loading stats:', error);
    }
  };

  const startArrowAnimation = () => {
    Animated.loop(
      Animated.sequence([
        Animated.timing(arrowAnimation, {
          toValue: 10,
          duration: 800,
          useNativeDriver: true,
        }),
        Animated.timing(arrowAnimation, {
          toValue: 0,
          duration: 800,
          useNativeDriver: true,
        }),
      ])
    ).start();
  };

  const animateNumber = (target: number, setter: (value: number) => void) => {
    const duration = 2000;
    const steps = 60;
    const increment = target / steps;
    let current = 0;

    const interval = setInterval(() => {
      current += increment;
      if (current >= target) {
        setter(target);
        clearInterval(interval);
      } else {
        setter(Math.floor(current));
      }
    }, duration / steps);
  };

  return (
    <SafeAreaView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Image
          source={require('../../assets/logo.png')} // Asegúrate de tener un logo
          style={styles.logo}
          resizeMode="contain"
        />
        <TouchableOpacity
          style={styles.viewWallButton}
          onPress={() => navigation.navigate('Grid' as never)}
        >
          <Animated.View
            style={{
              transform: [{ translateX: arrowAnimation }],
            }}
          >
            <Text style={styles.arrowIcon}>→</Text>
          </Animated.View>
          <Text style={styles.viewWallText}>Ver el muro</Text>
        </TouchableOpacity>
      </View>

      {/* Contenido principal */}
      <View style={styles.content}>
        <LinearGradient
          colors={[COLORS.background, COLORS.surface]}
          style={styles.heroSection}
        >
          <Text style={styles.title}>EverWall</Text>
          <Text style={styles.subtitle}>
            Tu imagen en la pared digital más grande del mundo
          </Text>

          <TouchableOpacity
            style={styles.ctaButton}
            onPress={() => navigation.navigate('Grid' as never)}
          >
            <Text style={styles.ctaButtonText}>
              ¡Sube tu imagen ahora!
            </Text>
          </TouchableOpacity>
        </LinearGradient>

        {/* Estadísticas */}
        <View style={styles.statsContainer}>
          <Text style={styles.statsTitle}>El muro está creciendo</Text>

          <View style={styles.statCard}>
            <Text style={styles.statNumber}>{animatedSold.toLocaleString()}</Text>
            <Text style={styles.statLabel}>Imágenes subidas</Text>
          </View>

          <View style={styles.statCard}>
            <Text style={styles.statNumber}>{animatedViews.toLocaleString()}</Text>
            <Text style={styles.statLabel}>Visualizaciones totales</Text>
          </View>

          <View style={styles.statCard}>
            <Text style={styles.statNumber}>
              {((stats.soldPixels / stats.totalPixels) * 100).toFixed(1)}%
            </Text>
            <Text style={styles.statLabel}>Del muro ocupado</Text>
          </View>
        </View>

        {/* Sección informativa */}
        <View style={styles.infoSection}>
          <Text style={styles.infoTitle}>¿Cómo funciona?</Text>

          <View style={styles.stepContainer}>
            <View style={styles.step}>
              <View style={styles.stepNumber}>
                <Text style={styles.stepNumberText}>1</Text>
              </View>
              <Text style={styles.stepText}>Elige un pixel disponible</Text>
            </View>

            <View style={styles.step}>
              <View style={styles.stepNumber}>
                <Text style={styles.stepNumberText}>2</Text>
              </View>
              <Text style={styles.stepText}>Sube tu imagen</Text>
            </View>

            <View style={styles.step}>
              <View style={styles.stepNumber}>
                <Text style={styles.stepNumberText}>3</Text>
              </View>
              <Text style={styles.stepText}>Completa el pago</Text>
            </View>

            <View style={styles.step}>
              <View style={styles.stepNumber}>
                <Text style={styles.stepNumberText}>4</Text>
              </View>
              <Text style={styles.stepText}>¡Tu imagen ya está en el muro!</Text>
            </View>
          </View>
        </View>
      </View>
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
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: COLORS.border,
  },
  logo: {
    width: 120,
    height: 40,
  },
  viewWallButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  arrowIcon: {
    color: COLORS.primary,
    fontSize: 24,
    fontWeight: 'bold',
  },
  viewWallText: {
    color: COLORS.primary,
    fontSize: 16,
    fontWeight: '600',
  },
  content: {
    flex: 1,
  },
  heroSection: {
    padding: 30,
    alignItems: 'center',
    minHeight: 300,
  },
  title: {
    fontSize: 48,
    fontWeight: 'bold',
    color: COLORS.text,
    marginBottom: 16,
    textAlign: 'center',
  },
  subtitle: {
    fontSize: 18,
    color: COLORS.textSecondary,
    textAlign: 'center',
    marginBottom: 40,
    lineHeight: 26,
  },
  ctaButton: {
    backgroundColor: COLORS.primary,
    paddingHorizontal: 40,
    paddingVertical: 16,
    borderRadius: 30,
    shadowColor: COLORS.primary,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 5,
  },
  ctaButtonText: {
    color: COLORS.text,
    fontSize: 18,
    fontWeight: 'bold',
  },
  statsContainer: {
    padding: 20,
    backgroundColor: COLORS.surface,
  },
  statsTitle: {
    color: COLORS.text,
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
    textAlign: 'center',
  },
  statCard: {
    backgroundColor: COLORS.background,
    borderRadius: 12,
    padding: 20,
    marginBottom: 12,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  statNumber: {
    color: COLORS.primary,
    fontSize: 36,
    fontWeight: 'bold',
    marginBottom: 8,
  },
  statLabel: {
    color: COLORS.textSecondary,
    fontSize: 14,
  },
  infoSection: {
    padding: 20,
    backgroundColor: COLORS.background,
  },
  infoTitle: {
    color: COLORS.text,
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
    textAlign: 'center',
  },
  stepContainer: {
    gap: 16,
  },
  step: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 16,
  },
  stepNumber: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: COLORS.primary,
    justifyContent: 'center',
    alignItems: 'center',
  },
  stepNumberText: {
    color: COLORS.text,
    fontSize: 18,
    fontWeight: 'bold',
  },
  stepText: {
    color: COLORS.text,
    fontSize: 16,
    flex: 1,
  },
});
