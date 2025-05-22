module.exports = (role) => (req, res, next) => {
  console.log('Role middleware: Checking role for user:', req.user);
  if (!req.user || req.user.role !== role) {
    console.log('Role middleware: Access denied, user role:', req.user?.role, 'required role:', role);
    return res.status(403).json({ message: 'Access denied: Insufficient permissions' });
  }
  console.log('Role middleware: Access granted, user role:', req.user.role);
  next();
};