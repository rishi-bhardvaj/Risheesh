import { createApp } from './app';
import { config } from './config';
import { checkDatabaseConnection } from './db';

const app = createApp();

async function start() {
  const isConnected = await checkDatabaseConnection();
  if (!isConnected) {
    console.error('Warning: Unable to connect to PostgreSQL database on startup.');
  } else {
    console.log('PostgreSQL database connected successfully.');
  }

  app.listen(config.port, () => {
    console.log(`Career OS Backend server running on port ${config.port} (env: ${config.nodeEnv})`);
  });
}

if (require.main === module) {
  start().catch((err) => {
    console.error('Fatal error during server startup:', err);
    process.exit(1);
  });
}
