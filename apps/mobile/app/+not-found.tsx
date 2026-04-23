import { Link, Stack } from 'expo-router';
import { Text, View } from 'react-native';

export default function NotFound() {
  return (
    <>
      <Stack.Screen options={{ title: 'Not Found' }} />
      <View className="flex-1 items-center justify-center bg-background px-6">
        <Text className="text-xl font-semibold text-text">Screen not found.</Text>
        <Link href="/" className="mt-4 text-primary underline">
          Go home
        </Link>
      </View>
    </>
  );
}
