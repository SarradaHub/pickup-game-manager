// Try to load design system config if it exists, otherwise use empty config
let designSystemConfig = { theme: { extend: {} } };
try {
  const path = require('path');
  const designSystemPath = path.resolve(__dirname, '../../platform/design-system/tailwind.config.js');
  designSystemConfig = require(designSystemPath);
} catch (e) {
  // Design system config not found, using defaults with manual color definitions
  console.warn('Design system config not found, using default Tailwind config with manual colors');
}

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js',
  ],
  safelist: [
    // Color backgrounds
    { pattern: /bg-(success|error|warning|info|primary|secondary)-(50|100|200|300|400|500|600|700|800|900|950)/ },
    // Color text
    { pattern: /text-(success|error|warning|info|primary|secondary)-(50|100|200|300|400|500|600|700|800|900|950)/ },
    // Color borders
    { pattern: /border-(l-|r-|t-|b-)?(success|error|warning|info|primary|secondary)-(50|100|200|300|400|500|600|700|800|900|950)/ },
    // Gradients
    { pattern: /from-(success|error|warning|info|primary|secondary)-(50|100|200|300|400|500|600|700|800|900|950)/ },
    { pattern: /to-(success|error|warning|info|primary|secondary)-(50|100|200|300|400|500|600|700|800|900|950)/ },
    { pattern: /via-(success|error|warning|info|primary|secondary)-(50|100|200|300|400|500|600|700|800|900|950)/ },
  ],
  theme: {
    extend: {
      ...(designSystemConfig.theme?.extend || {}),
      // Fallback colors if design system config fails to load
      colors: designSystemConfig.theme?.extend?.colors || {
        primary: {
          50: '#eff6ff',
          100: '#dbeafe',
          200: '#bfdbfe',
          300: '#93c5fd',
          400: '#60a5fa',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
          800: '#1e40af',
          900: '#1e3a8a',
          950: '#172554',
        },
        secondary: {
          50: '#faf5ff',
          100: '#f3e8ff',
          200: '#e9d5ff',
          300: '#d8b4fe',
          400: '#c084fc',
          500: '#a855f7',
          600: '#9333ea',
          700: '#7e22ce',
          800: '#6b21a8',
          900: '#581c87',
          950: '#3b0764',
        },
        success: {
          50: '#f0fdf4',
          100: '#dcfce7',
          200: '#bbf7d0',
          300: '#86efac',
          400: '#4ade80',
          500: '#22c55e',
          600: '#16a34a',
          700: '#15803d',
          800: '#166534',
          900: '#14532d',
          950: '#052e16',
        },
        warning: {
          50: '#fefce8',
          100: '#fef9c3',
          200: '#fef08a',
          300: '#fde047',
          400: '#facc15',
          500: '#eab308',
          600: '#ca8a04',
          700: '#a16207',
          800: '#854d0e',
          900: '#713f12',
          950: '#422006',
        },
        error: {
          50: '#fef2f2',
          100: '#fee2e2',
          200: '#fecaca',
          300: '#fca5a5',
          400: '#f87171',
          500: '#ef4444',
          600: '#dc2626',
          700: '#b91c1c',
          800: '#991b1b',
          900: '#7f1d1d',
          950: '#450a0a',
        },
        info: {
          50: '#eff6ff',
          100: '#dbeafe',
          200: '#bfdbfe',
          300: '#93c5fd',
          400: '#60a5fa',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
          800: '#1e40af',
          900: '#1e3a8a',
          950: '#172554',
        },
        neutral: {
          50: '#f9fafb',
          100: '#f3f4f6',
          200: '#e5e7eb',
          300: '#d1d5db',
          400: '#9ca3af',
          500: '#6b7280',
          600: '#4b5563',
          700: '#374151',
          800: '#1f2937',
          900: '#111827',
          950: '#030712',
        },
      },
    },
  },
  plugins: [],
};

