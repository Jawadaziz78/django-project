/** @type {import('next').NextConfig} */
const nextConfig = {
  // 1. Dynamic Base Path
  basePath: process.env.BASE_URL || '',
  
  // 2. Asset Prefix
  assetPrefix: process.env.BASE_URL || '',

  reactStrictMode: true,
};

module.exports = nextConfig;
