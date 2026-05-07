import { defineConfig } from 'vite'
import tailwindcss from '@tailwindcss/vite'
import { resolve } from 'path'
export default defineConfig({
  plugins: [tailwindcss()],
  build: {
    outDir: resolve(__dirname, 'static/dist'),
    rollupOptions: {
      input: resolve(__dirname, 'static/style.css'),
      output: {
        assetFileNames: '[name][extname]',
      },
    },
  },
})