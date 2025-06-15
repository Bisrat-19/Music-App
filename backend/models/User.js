const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  fullName: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['listener', 'artist', 'admin'], default: 'listener' },
  watchlist: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Song' }],
  profileImagePath: { type: String, default: null },
  following: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User', default: [] }], // IDs of followed users (artists)
  followingCount: { type: Number, default: 0 },
  followers: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User', default: [] }], // IDs of followers (listeners or artists)
  followerCount: { type: Number, default: 0 },
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

const User = mongoose.models.User || mongoose.model('User', userSchema);

module.exports = User;