import { serve } from '@hono/node-server';
import app from './dist/server.js';

const port = Number(process.env.PORT) || 3000;

console.log(`====================================================`);
console.log(`🎵 Self-Hosted JioSaavn Engine is running!`);
console.log(`📡 URL: http://localhost:${port}`);
console.log(`📑 OpenAPI / Swagger UI: http://localhost:${port}/swagger`);
console.log(`====================================================`);

serve({
  fetch: app.fetch,
  port
});
