const jwt = require('jsonwebtoken');
require('dotenv').config();

const protect = (req, res, next) => {
  const authHeader = req.headers.authorization;
  console.log('Auth Middleware: Authorization header:', authHeader);

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    console.log('Auth Middleware: Invalid or missing Authorization header');
    return res.status(401).json({ message: 'Unauthorized: Missing or invalid token' });
  }

  const token = authHeader.split(' ')[1];
  console.log('Auth Middleware: Extracted token:', token);

  if (!token) {
    console.log('Auth Middleware: No token provided after splitting');
    return res.status(401).json({ message: 'Unauthorized: No token provided' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    console.log('Auth Middleware: Token decoded:', decoded);
    req.user = decoded; // Attach decoded user (should include id and role)
    next();
  } catch (err) {
    console.error('Auth Middleware: Token verification failed:', err.message);
    res.status(401).json({ message: 'Invalid token' }); // Changed to 401 for consistency
  }
};

module.exports = protect;