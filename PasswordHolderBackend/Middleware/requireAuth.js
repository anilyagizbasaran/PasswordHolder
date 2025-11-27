const jwt = require('jsonwebtoken');

const jwtSecret = process.env.JWT_SECRET || 'development-secret';

function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Yetkisiz erişim: token bulunamadı' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const payload = jwt.verify(token, jwtSecret);
    req.user = {
      id: payload.sub,
      email: payload.email,
      name: payload.name,
      department: payload.department,
      departmentId: payload.departmentId,
    };
    return next();
  } catch (error) {
    console.error('requireAuth error:', error);
    return res.status(401).json({ message: 'Yetkisiz erişim: geçersiz veya süresi dolmuş token' });
  }
}

module.exports = requireAuth;

