/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  transpilePackages: ['@fittrack/shared'],
  experimental: {
    typedRoutes: false,
  },
};

export default nextConfig;
