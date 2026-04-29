import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./app/**/*.{ts,tsx}', './components/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        // Koyu tema birincil — alt lig koçu sahada akşam kullanır.
        bg: {
          DEFAULT: '#0a0a0a',
          elevated: '#141414',
          card: '#1c1c1c',
        },
        border: {
          DEFAULT: '#2a2a2a',
          strong: '#404040',
        },
        accent: {
          DEFAULT: '#a3e635', // electric lime
          hover: '#bef264',
          muted: '#65a30d',
        },
        text: {
          DEFAULT: '#fafafa',
          muted: '#a3a3a3',
          dim: '#737373',
        },
        danger: '#ef4444',
        warn: '#f59e0b',
        success: '#22c55e',
      },
      fontFamily: {
        sans: ['system-ui', '-apple-system', 'Segoe UI', 'Roboto', 'sans-serif'],
        display: ['system-ui', 'sans-serif'],
      },
      borderRadius: {
        DEFAULT: '8px',
      },
    },
  },
  plugins: [],
};

export default config;
