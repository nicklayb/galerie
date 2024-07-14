// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration
module.exports = {
  content: ["./js/**/*.js", "../lib/*_web.ex", "../lib/*_web/**/*.*ex"],
  theme: {
    extend: {
      colors: {
        "true-gray-50": "#fafafa",
        "true-gray-100": "#f5f5f5",
        "true-gray-200": "#e5e5e5",
        "true-gray-300": "#d4d4d4",
        "true-gray-400": "#a3a3a3",
        "true-gray-500": "#737373",
        "true-gray-600": "#525252",
        "true-gray-700": "#404040",
        "true-gray-800": "#262626",
        "true-gray-900": "#171717",
      },
    },
    rotate: {
      "90": "90deg",
      "180": "180deg",
      "270": "270deg"
    }
  },
  plugins: [require("@tailwindcss/forms")],
};
