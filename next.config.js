/** @type {import('next').NextConfig} */
const nextConfig = {
  basePath: process.env.BASE_URL || '',
  assetPrefix: process.env.BASE_URL || '',
  reactStrictMode: true,
};

module.exports = nextConfig;
