const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter variable', ...defaultTheme.fontFamily.sans],
      },
      colors: {
        light: '#F8F2EE',
        dark: '#4A301E',
        accent: '#f2b0aa',
        'accent-dark': '#E66A5F',
        'accent-light': '#F8D8D5',
      },
      keyframes: {
        'slide-fade-in': {
          '0%': { opacity: 0, transform: 'translateY(20px)' },
          '100%': { opacity: 1, transform: 'translateY(0)' },
        },
      },
      animation: {
        'slide-fade-in': 'slide-fade-in 0.5s ease-out forwards',
      },
      animationDelay: {
        '100': '100ms',
        '200': '200ms',
        '300': '300ms',
        '400': '400ms',
      },
    },
  },
  plugins: [
    function ({ addUtilities, theme, e }) {
      const delays = theme('animationDelay');
      const utilities = Object.keys(delays).reduce((acc, key) => {
        acc[`.${e(`animation-delay-${key}`)}`] = {
          animationDelay: delays[key],
        };
        return acc;
      }, {});
      addUtilities(utilities, ['responsive']);
    },
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries'),
  ]
}
