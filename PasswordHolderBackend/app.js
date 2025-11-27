const express = require('express');
const dotenv = require('dotenv');
const userRoutes = require('./routes/userRoutes');
const passwordholderRoutes = require('./routes/passwordholderRoutes');
const departmentRoutes = require('./routes/departmentRoutes');

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());
app.use('/api/users', userRoutes);
app.use('/api/passwordholder', passwordholderRoutes);
app.use('/api/departments', departmentRoutes);

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.listen(port, () => {
  console.log(`Sunucu port ${port} üzerinde çalışıyor`);
});