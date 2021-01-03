module.exports = {
  purge: [
    '../lib/helix_web/live/**/*.ex',
    '../lib/helix_web/live/**/*.leex',
    '../lib/helix_web/templates/**/*.ex',
    '../lib/helix_web/templates/**/*.leex',
    '../lib/helix_web/views/**/*.ex',
    './js/**/*.js',
  ],
  darkMode: false, // or 'media' or 'class'
  theme: {
    extend: {},
  },
  variants: {
    extend: {},
  },
  plugins: [],
}
