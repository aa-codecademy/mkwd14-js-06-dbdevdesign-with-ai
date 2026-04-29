import 'dotenv/config';
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import router from './src/routes/index.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const publicDirPath = path.join(__dirname, 'public');

const PORT = process.env.PORT || 3000;
const HOSTNAME = process.env.HOSTNAME || 'localhost';

const app = express();

// middleware
app.use(express.json());
app.use('/api', router);
app.use(express.static(publicDirPath));

app.listen(PORT, HOSTNAME, () => {
	console.log(`Server is running on http://${HOSTNAME}:${PORT}`);
});
