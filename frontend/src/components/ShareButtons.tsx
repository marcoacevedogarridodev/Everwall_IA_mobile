import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Alert } from 'react-native';
import * as Clipboard from 'expo-clipboard';
import Share from 'react-native-share';
import { Pixel } from '../types';
import { COLORS } from '../utils/constants';

interface ShareButtonsProps {
  pixel: Pixel;
}

export const ShareButtons: React.FC<ShareButtonsProps> = ({ pixel }) => {
  const shareUrl = `https://everwall.com/pixel/${pixel.search_code}`;
  const shareMessage = `¡Mira mi pixel en EverWall! 🎨\nCódigo: ${pixel.display_code}\n${shareUrl}`;

  const handleCopyCode = async () => {
    await Clipboard.setStringAsync(pixel.display_code);
    Alert.alert('¡Copiado!', 'Código copiado al portapapeles');
  };

  const handleCopyLink = async () => {
    await Clipboard.setStringAsync(shareUrl);
    Alert.alert('¡Copiado!', 'Enlace copiado al portapapeles');
  };

  const handleShare = async () => {
    try {
      await Share.open({
        message: shareMessage,
        title: 'Compartir Pixel - EverWall',
      });
    } catch (error) {
      console.log('Share cancelled');
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Compartir</Text>

      <View style={styles.buttonContainer}>
        <TouchableOpacity style={styles.button} onPress={handleCopyCode}>
          <Text style={styles.buttonText}>📋 Copiar código</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.button} onPress={handleCopyLink}>
          <Text style={styles.buttonText}>🔗 Copiar enlace</Text>
        </TouchableOpacity>

        <TouchableOpacity style={[styles.button, styles.shareButton]} onPress={handleShare}>
          <Text style={styles.buttonText}>📤 Compartir</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    marginTop: 16,
  },
  title: {
    color: COLORS.text,
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 12,
  },
  buttonContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    gap: 8,
  },
  button: {
    flex: 1,
    padding: 10,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: COLORS.primary,
    alignItems: 'center',
  },
  shareButton: {
    backgroundColor: COLORS.primary,
  },
  buttonText: {
    color: COLORS.text,
    fontSize: 12,
  },
});
