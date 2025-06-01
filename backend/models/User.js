const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

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
  watchlist: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Song',
    },
  ],
  profileImagePath: {
    type: String, // Stores the path to the uploaded image (e.g., /uploads/profile/123456789-image.jpg)
    default: null, // Optional field, can be null if no image is uploaded
  },
}, {
  timestamps: true
});

userSchema.pre('save', async function (next) {
  if (this.isModified('password')) {
    this.password = await bcrypt.hash(this.password, 10);
  }
  next();
});

userSchema.methods.comparePassword = async function (password) {
  return await bcrypt.compare(password, this.password);
};

// Check if the model is already registered, and register it only if not
const User = mongoose.models.User || mongoose.model('User', userSchema);

module.exports = User;