import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import { getLocales } from 'expo-localization';
import enCommon from './locales/en/common.json';
import trCommon from './locales/tr/common.json';

export const supportedLocales = ['en', 'tr'] as const;
export type SupportedLocale = (typeof supportedLocales)[number];

function resolveDeviceLocale(): SupportedLocale {
  const locales = getLocales();
  const device = locales[0]?.languageCode;
  return supportedLocales.includes(device as SupportedLocale)
    ? (device as SupportedLocale)
    : 'en';
}

void i18n.use(initReactI18next).init({
  resources: {
    en: { common: enCommon },
    tr: { common: trCommon },
  },
  lng: resolveDeviceLocale(),
  fallbackLng: 'en',
  defaultNS: 'common',
  ns: ['common'],
  interpolation: { escapeValue: false },
  compatibilityJSON: 'v4',
});

export default i18n;
