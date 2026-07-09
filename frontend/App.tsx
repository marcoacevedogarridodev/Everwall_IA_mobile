import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';
import { StripeProvider } from '@stripe/stripe-react-native';
import { StatusBar } from 'expo-status-bar';
import { HomeScreen } from './screens/HomeScreen';
import { GridScreen } from './screens/GridScreen';
import { COLORS } from './utils/constants';

const Stack = createStackNavigator();

export default function App() {
  return (
    <StripeProvider publishableKey="tu_llave_publica_de_stripe_aqui">
      <NavigationContainer>
        <StatusBar style="light" />
        <Stack.Navigator
          initialRouteName="Home"
          screenOptions={{
            headerShown: false,
            cardStyle: { backgroundColor: COLORS.background },
          }}
        >
          <Stack.Screen name="Home" component={HomeScreen} />
          <Stack.Screen name="Grid" component={GridScreen} />
        </Stack.Navigator>
      </NavigationContainer>
    </StripeProvider>
  );
}
