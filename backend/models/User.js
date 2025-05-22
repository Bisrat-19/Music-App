const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  fullName: {
    type: String,
    required: true,
  },
  email: {
    type: String,
    required: true,
    unique: true,
  },
  password: {
    type: String,
    required: true,
  },
  role: {
    type: String,
    enum: ['listener', 'artist', 'admin'],
    default: 'listener',
  },
}, {
  timestamps: true
});

module.exports = mongoose.model('User', userSchema);
