const express = require('express');
const router = express.Router();
const protect = require('../middleware/authMiddleware');

router.get('/me', protect, (req, res) => {
  res.json({
    message: `Hello ${req.user.id}`,
    role: req.user.role
  });
});

module.exports = router;
