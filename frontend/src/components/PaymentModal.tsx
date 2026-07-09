import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Modal,
  TouchableOpacity,
  TextInput,
  ScrollView,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { useStripe } from '@stripe/stripe-react-native';
import { COLORS } from '../utils/constants';
import { ImageUploader } from './ImageUploader';
import { pixelService } from '../services/pixelService';
import { CreatePurchaseResponse } from '../types';

interface PaymentModalProps {
  visible: boolean;
  onClose: () => void;
  pixelX: number;
  pixelY: number;
  priceUSD: string;
  priceCLP: number;
  onSuccess: (pixel: any) => void;
}

export const PaymentModal: React.FC<PaymentModalProps> = ({
  visible,
  onClose,
  pixelX,
  pixelY,
  priceUSD,
  priceCLP,
  onSuccess,
}) => {
  const { initPaymentSheet, presentPaymentSheet } = useStripe();

  const [step, setStep] = useState(1);
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    message: '',
    currency: 'USD' as 'USD' | 'CLP',
  });
  const [images, setImages] = useState<string[]>([]);
  const [purchaseData, setPurchaseData] = useState<CreatePurchaseResponse | null>(null);

  const handleInputChange = (field: string, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  const validateForm = () => {
    if (!formData.name.trim()) {
      Alert.alert('Error', 'Por favor ingresa tu nombre');
      return false;
    }
    if (!formData.email.trim() || !formData.email.includes('@')) {
      Alert.alert('Error', 'Por favor ingresa un email válido');
      return false;
    }
    if (images.length === 0) {
      Alert.alert('Error', 'Debes subir al menos una imagen');
      return false;
    }
    return true;
  };

  const handleNextStep = async () => {
    if (!validateForm()) return;

    setLoading(true);
    try {
      // 1. Crear sesión de compra
      const response = await pixelService.createPurchaseSession({
        x: pixelX,
        y: pixelY,
        owner_name: formData.name,
        owner_email: formData.email,
        owner_message: formData.message,
        currency: formData.currency,
      });

      if (response) {
        setPurchaseData(response);

        // 2. Subir imágenes
        const formDataUpload = new FormData();
        images.forEach((image, index) => {
          formDataUpload.append('images', {
            uri: image,
            type: 'image/jpeg',
            name: `pixel_${pixelX}_${pixelY}_${index}.jpg`,
          } as any);
        });

        await pixelService.uploadPixelImage(formDataUpload);

        setStep(2);

        // 3. Inicializar Stripe
        await initializePayment(response.client_secret);
      }
    } catch (error: any) {
      Alert.alert('Error', error.message || 'Error al procesar la solicitud');
    } finally {
      setLoading(false);
    }
  };

  const initializePayment = async (clientSecret: string) => {
    const { error } = await initPaymentSheet({
      paymentIntentClientSecret: clientSecret,
      merchantDisplayName: 'EverWall',
      allowsDelayedPaymentMethods: true,
      returnURL: 'everwall://stripe-redirect',
    });

    if (error) {
      Alert.alert('Error', error.message);
    }
  };

  const handlePayment = async () => {
    setLoading(true);
    try {
      const { error } = await presentPaymentSheet();

      if (error) {
        if (error.code === 'Canceled') {
          Alert.alert('Pago cancelado', 'Has cancelado el proceso de pago');
        } else {
          Alert.alert('Error', error.message);
        }
      } else {
        // Pago exitoso
        if (purchaseData) {
          const pixel = await pixelService.confirmPurchase(
            purchaseData.session_id,
            purchaseData.payment_intent_id
          );

          Alert.alert(
            '¡Éxito!',
            'Tu pixel ha sido comprado exitosamente. Recibirás un correo con los detalles.',
            [
              {
                text: 'Ver mi pixel',
                onPress: () => {
                  onSuccess(pixel);
                  onClose();
                },
              },
            ]
          );
        }
      }
    } catch (error: any) {
      Alert.alert('Error', error.message);
    } finally {
      setLoading(false);
    }
  };

  const renderStep1 = () => (
    <ScrollView style={styles.form}>
      <Text style={styles.stepTitle}>Información del comprador</Text>

      <Text style={styles.positionLabel}>
        Posición seleccionada: ({pixelX}, {pixelY})
      </Text>

      <View style={styles.inputGroup}>
        <Text style={styles.label}>Nombre *</Text>
        <TextInput
          style={styles.input}
          placeholder="Tu nombre"
          placeholderTextColor={COLORS.textSecondary}
          value={formData.name}
          onChangeText={(text) => handleInputChange('name', text)}
        />
      </View>

      <View style={styles.inputGroup}>
        <Text style={styles.label}>Email *</Text>
        <TextInput
          style={styles.input}
          placeholder="tu@email.com"
          placeholderTextColor={COLORS.textSecondary}
          keyboardType="email-address"
          autoCapitalize="none"
          value={formData.email}
          onChangeText={(text) => handleInputChange('email', text)}
        />
      </View>

      <View style={styles.inputGroup}>
        <Text style={styles.label}>Mensaje (opcional)</Text>
        <TextInput
          style={[styles.input, styles.textArea]}
          placeholder="Un mensaje para tu pixel..."
          placeholderTextColor={COLORS.textSecondary}
          multiline
          numberOfLines={3}
          value={formData.message}
          onChangeText={(text) => handleInputChange('message', text)}
        />
      </View>

      <ImageUploader onImagesSelected={setImages} maxImages={5} />

      <View style={styles.currencySelector}>
        <Text style={styles.label}>Moneda de pago</Text>
        <View style={styles.currencyButtons}>
          <TouchableOpacity
            style={[
              styles.currencyButton,
              formData.currency === 'USD' && styles.currencyButtonActive,
            ]}
            onPress={() => handleInputChange('currency', 'USD')}
          >
            <Text
              style={[
                styles.currencyButtonText,
                formData.currency === 'USD' && styles.currencyButtonTextActive,
              ]}
            >
              USD (${priceUSD})
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[
              styles.currencyButton,
              formData.currency === 'CLP' && styles.currencyButtonActive,
            ]}
            onPress={() => handleInputChange('currency', 'CLP')}
          >
            <Text
              style={[
                styles.currencyButtonText,
                formData.currency === 'CLP' && styles.currencyButtonTextActive,
              ]}
            >
              CLP (${priceCLP.toLocaleString()})
            </Text>
          </TouchableOpacity>
        </View>
      </View>

      <TouchableOpacity
        style={[styles.button, loading && styles.buttonDisabled]}
        onPress={handleNextStep}
        disabled={loading}
      >
        {loading ? (
          <ActivityIndicator color={COLORS.text} />
        ) : (
          <Text style={styles.buttonText}>Continuar al pago</Text>
        )}
      </TouchableOpacity>
    </ScrollView>
  );

  const renderStep2 = () => (
    <View style={styles.paymentContainer}>
      <Text style={styles.stepTitle}>Completar pago</Text>

      <View style={styles.paymentSummary}>
        <Text style={styles.summaryText}>
          Pixel: ({pixelX}, {pixelY})
        </Text>
        <Text style={styles.summaryText}>
          Total: {formData.currency === 'USD' ? `$${priceUSD} USD` : `$${priceCLP.toLocaleString()} CLP`}
        </Text>
      </View>

      <TouchableOpacity
        style={[styles.button, styles.paymentButton]}
        onPress={handlePayment}
        disabled={loading}
      >
        {loading ? (
          <ActivityIndicator color={COLORS.text} />
        ) : (
          <Text style={styles.buttonText}>Pagar con Stripe</Text>
        )}
      </TouchableOpacity>

      <TouchableOpacity
        style={styles.backButton}
        onPress={() => setStep(1)}
      >
        <Text style={styles.backButtonText}>← Volver</Text>
      </TouchableOpacity>
    </View>
  );

  return (
    <Modal
      visible={visible}
      animationType="slide"
      transparent={true}
      onRequestClose={onClose}
    >
      <View style={styles.modalContainer}>
        <View style={styles.modalContent}>
          <TouchableOpacity style={styles.closeButton} onPress={onClose}>
            <Text style={styles.closeButtonText}>✕</Text>
          </TouchableOpacity>

          {step === 1 ? renderStep1() : renderStep2()}
        </View>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  modalContainer: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.9)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalContent: {
    width: '90%',
    maxHeight: '80%',
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
  form: {
    marginTop: 20,
  },
  stepTitle: {
    color: COLORS.primary,
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 20,
  },
  positionLabel: {
    color: COLORS.text,
    fontSize: 14,
    marginBottom: 20,
    padding: 10,
    backgroundColor: COLORS.background,
    borderRadius: 8,
    textAlign: 'center',
  },
  inputGroup: {
    marginBottom: 16,
  },
  label: {
    color: COLORS.text,
    fontSize: 14,
    marginBottom: 8,
  },
  input: {
    backgroundColor: COLORS.background,
    borderRadius: 8,
    padding: 12,
    color: COLORS.text,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  textArea: {
    minHeight: 80,
    textAlignVertical: 'top',
  },
  currencySelector: {
    marginVertical: 16,
  },
  currencyButtons: {
    flexDirection: 'row',
    gap: 12,
  },
  currencyButton: {
    flex: 1,
    padding: 12,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: COLORS.border,
    alignItems: 'center',
  },
  currencyButtonActive: {
    backgroundColor: COLORS.primary,
    borderColor: COLORS.primary,
  },
  currencyButtonText: {
    color: COLORS.text,
    fontSize: 14,
  },
  currencyButtonTextActive: {
    color: COLORS.text,
    fontWeight: 'bold',
  },
  button: {
    backgroundColor: COLORS.primary,
    padding: 16,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 20,
    marginBottom: 20,
  },
  buttonDisabled: {
    opacity: 0.5,
  },
  buttonText: {
    color: COLORS.text,
    fontSize: 16,
    fontWeight: 'bold',
  },
  paymentContainer: {
    marginTop: 40,
  },
  paymentSummary: {
    backgroundColor: COLORS.background,
    padding: 16,
    borderRadius: 8,
    marginVertical: 20,
  },
  summaryText: {
    color: COLORS.text,
    fontSize: 16,
    marginVertical: 4,
  },
  paymentButton: {
    marginTop: 30,
  },
  backButton: {
    padding: 16,
    alignItems: 'center',
  },
  backButtonText: {
    color: COLORS.primary,
    fontSize: 16,
  },
});
