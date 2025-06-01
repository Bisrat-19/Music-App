const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

exports.register = async (req, res) => {
  const { fullName, email, password, role } = req.body;

  try {
    console.log(`Register attempt: email=${email}, role=${role || 'listener'}`);
    const existing = await User.findOne({ email });
    if (existing) {
      console.log(`User already exists: ${email}`);
      return res.status(400).json({ message: 'User already exists' });
    }

    // Pass the raw password; let the model hash it
    const user = await User.create({
      fullName,
      email,
      password, // Raw password
      role: role || 'listener'
    });
    console.log(`User created: ${user._id}, email=${email}`);

    const token = jwt.sign({ id: user._id, role: user.role }, process.env.JWT_SECRET, {
      expiresIn: '7d'
    });
    console.log(`Token generated for ${email}`);

    res.status(201).json({ user, token });
  } catch (err) {
    console.error(`Register error for ${email}: ${err.message}`);
    res.status(500).json({ message: err.message });
  }
};

exports.login = async (req, res) => {
  const { email, password } = req.body;

  try {
    console.log(`Login attempt: email=${email}`);
    const user = await User.findOne({ email });
    if (!user) {
      console.log(`User not found: ${email}`);
      return res.status(400).json({ message: 'Invalid credentials' });
    }
    console.log(`User found: ${user._id}, email=${user.email}`);

    const isMatch = await user.comparePassword(password); // Use the model method
    if (!isMatch) {
      console.log(`Password mismatch for ${email}. Provided: ${password}, Stored: ${user.password}`);
      return res.status(400).json({ message: 'Invalid credentials' });
    }
    console.log(`Password matched for ${email}`);

    const token = jwt.sign({ id: user._id, role: user.role }, process.env.JWT_SECRET, {
      expiresIn: '7d'
    });
    console.log(`Token generated for ${email}`);

    res.status(200).json({ user, token });
  } catch (err) {
    console.error(`Login error for ${email}: ${err.message}`);
    res.status(500).json({ message: err.message });
  }
};