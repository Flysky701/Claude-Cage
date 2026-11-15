import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  base: "/",
  publicDir: false,
  build: {
    outDir: "../internal/windowslite/web",
    emptyOutDir: true,
    rolldownOptions: { input: "windows-lite.html" },
  },
});
