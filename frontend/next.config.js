/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  // Proxy /api/* → backend:8080 so frontend and backend share one port in prod
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: `${process.env.BACKEND_URL || 'http://backend:8080'}/api/:path*`,
      },
    ];
  },
};

module.exports = nextConfig;
