import 'dotenv/config';
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import router from './src/routes/index.js';

// In ESM we do not have __dirname, so we recreate it from import.meta.url.
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const publicDirPath = path.join(__dirname, 'public');

// App and DB settings are loaded from environment variables with safe defaults.
const PORT = process.env.PORT || 3000;
const HOSTNAME = process.env.HOSTNAME || 'localhost';

const app = express();

// Parse JSON request bodies (needed for POST/PUT/PATCH APIs).
app.use(express.json());

// Mount all API routes under /api.
app.use('/api', router);

// Serve frontend files from /public.
app.use(express.static(publicDirPath));

app.listen(PORT, HOSTNAME, () => {
	console.log(`Server is running on http://${HOSTNAME}:${PORT}`);
});
