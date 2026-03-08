const express = require('express');
const { version } = require('./package.json');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'ok',
        uptime: process.uptime()
    });
});

app.get('/version', (req, res) => {
    res.send({ version });
});

app.get('/', (req, res) => {
    res.send('Hello from Dockerized Express app 🚀');
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
});
