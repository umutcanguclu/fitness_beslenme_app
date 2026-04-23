import { View, Text, Pressable } from 'react-native';
import { useTranslation } from 'react-i18next';
import { SafeAreaView } from 'react-native-safe-area-context';
import i18n from '../src/i18n';

export default function Landing() {
  const { t } = useTranslation();

  const toggleLocale = () => {
    const next = i18n.language === 'tr' ? 'en' : 'tr';
    void i18n.changeLanguage(next);
  };

  return (
    <SafeAreaView className="flex-1 bg-background">
      <View className="flex-1 items-center justify-center px-6">
        <Text className="font-display text-5xl tracking-wide text-primary">
          {t('app.name')}
        </Text>
        <Text className="mt-2 text-base text-text-muted">{t('app.tagline')}</Text>

        <View className="mt-12 w-full rounded-2xl border border-border bg-surface p-6">
          <Text className="text-lg font-semibold text-text">
            {t('dashboard.welcome')}
          </Text>
          <Text className="mt-2 text-sm text-text-muted">
            {t('dashboard.noData')}
          </Text>
        </View>

        <Pressable
          onPress={toggleLocale}
          className="mt-8 rounded-full border border-primary px-6 py-3"
        >
          <Text className="font-semibold text-primary">
            {i18n.language.toUpperCase()} ↔
          </Text>
        </Pressable>
      </View>
    </SafeAreaView>
  );
}
