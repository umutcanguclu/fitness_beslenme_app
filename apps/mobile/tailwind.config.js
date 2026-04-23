/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/**/*.{ts,tsx}',
    './src/**/*.{ts,tsx}',
  ],
  presets: [require('nativewind/preset')],
  theme: {
    extend: {
      colors: {
        background: '#0B0F14',
        surface: '#121821',
        surfaceAlt: '#1A2230',
        border: '#25303F',
        text: {
          DEFAULT: '#E6EEF7',
          muted: '#8AA0B8',
          dim: '#5C718A',
        },
        primary: {
          DEFAULT: '#C6FF3D',
          foreground: '#0B0F14',
        },
        accent: {
          DEFAULT: '#1BE1C1',
          foreground: '#0B0F14',
        },
        danger: '#FF5D73',
        warning: '#FFB020',
        success: '#31D17B',
      },
      fontFamily: {
        sans: ['Inter', 'System'],
        display: ['"Barlow Condensed"', 'Inter', 'System'],
      },
    },
  },
  plugins: [],
};
