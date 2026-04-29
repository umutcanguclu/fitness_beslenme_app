/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  transpilePackages: ['@fittrack/shared'],
  // Statik export sadece production build sırasında (Capacitor APK için).
  // Dev modunda devre dışı — dynamic route'lar serbestçe render olabilsin.
  ...(process.env.NEXT_BUILD_STATIC === 'true'
    ? { output: 'export', images: { unoptimized: true }, trailingSlash: true }
    : {}),
};

export default nextConfig;
