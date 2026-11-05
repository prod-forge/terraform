const express = require('express');
const { version } = require('./package.json');
const app = express();
const PORT = process.env.PORT || 3000;

const health = (req, res) => {
    res.status(200).json({
        status: 'ok',
        uptime: process.uptime()
    });
};

// /health is the ALB target group check, /health/live the ECS container check.
app.get('/health', health);
app.get('/health/live', health);

app.get('/version', (req, res) => {
    res.send({ version });
});

app.get('/', (req, res) => {
    res.send('Hello from Dockerized Express app 🚀');
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
});
