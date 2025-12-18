/** @type {import('next').NextConfig} */
const nextConfig = {
  // 1. Dynamic Base Path (The "Dist Thing")
  // If the env variable exists (from deploy.yml), use it. Otherwise, use empty string.
  basePath: process.env.BASE_URL || '',
  
  // 2. Asset Prefix (Ensures CSS/JS load from the correct sub-folder)
  assetPrefix: process.env.BASE_URL || '',

  // Standard Next.js settings...
  reactStrictMode: true,
};

module.exports = nextConfig;
