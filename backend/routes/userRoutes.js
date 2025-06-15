const express = require('express');
const router = express.Router();
const protect = require('../middleware/authMiddleware');
const multer = require('multer');
const path = require('path');
const User = require('../models/User');
const mongoose = require('mongoose');

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadPath = path.join(__dirname, '../uploads/profile');
    if (!require('fs').existsSync(uploadPath)) {
      require('fs').mkdirSync(uploadPath, { recursive: true });
    }
    cb(null, uploadPath);
  },
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}-${file.originalname}`);
  },
});
const upload = multer({ storage });

// Get current user profile
router.get('/me', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('fullName role profileImagePath followingCount followerCount');
    if (!user) return res.status(404).json({ message: 'User not found' });
    console.log('GET /me: User data sent:', user);
    res.json(user);
  } catch (error) {
    console.error('GET /me Error:', error.message);
    res.status(500).json({ message: 'Error fetching user', error: error.message });
  }
});

// Get user by ID
router.get('/:id', protect, async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('fullName role profileImagePath followingCount followerCount following followers');
    if (!user) return res.status(404).json({ message: 'User not found' });
    console.log('GET /:id: User data sent:', user);
    res.json(user);
  } catch (error) {
    console.error('GET /:id Error:', error.message);
    res.status(500).json({ message: 'Error fetching user', error: error.message });
  }
});

// Update user profile image
router.put('/:id/profile-image', protect, upload.single('profileImage'), async (req, res) => {
  try {
    const userId = req.params.id;
    const profileImagePath = req.file ? `/uploads/profile/${req.file.filename}` : null;

    console.log('PUT /profile-image: Uploaded file:', req.file);
    if (!profileImagePath) {
      return res.status(400).json({ message: 'No image uploaded' });
    }

    if (userId !== req.user.id.toString()) {
      return res.status(403).json({ message: 'Unauthorized to update this profile' });
    }

    const updatedUser = await User.findByIdAndUpdate(
      userId,
      { profileImagePath },
      { new: true, select: 'fullName role profileImagePath' }
    );
    if (!updatedUser) {
      return res.status(404).json({ message: 'User not found' });
    }
    console.log('PUT /profile-image: User updated:', updatedUser);
    res.status(200).json(updatedUser);
  } catch (error) {
    console.error('PUT /profile-image Error:', error.message);
    res.status(500).json({ message: 'Error updating profile image', error: error.message });
  }
});

// Follow an artist
router.post('/follow', protect, async (req, res) => {
  try {
    const { artistId } = req.body;
    const followerId = req.user.id;

    console.log('POST /follow: Request received - artistId:', artistId, 'followerId:', followerId);
    if (!mongoose.Types.ObjectId.isValid(artistId)) {
      return res.status(400).json({ message: 'Invalid artist ID' });
    }

    if (followerId === artistId) {
      return res.status(400).json({ message: 'Cannot follow yourself' });
    }

    const follower = await User.findById(followerId);
    const followed = await User.findById(artistId);

    if (!follower || !followed || followed.role !== 'artist') {
      return res.status(404).json({ message: 'Artist not found' });
    }

    if (!follower.following.includes(artistId)) {
      follower.following.push(artistId);
      follower.followingCount = follower.following.length;
      followed.followers.push(followerId);
      followed.followerCount = followed.followers.length;
      await follower.save({ validateBeforeSave: false });
      await followed.save({ validateBeforeSave: false });
      console.log('POST /follow: Updated follower:', follower);
      console.log('POST /follow: Updated followed:', followed);
      res.status(200).json({
        message: 'Followed successfully',
        follower: await User.findById(followerId).select('followingCount'),
        followed: await User.findById(artistId).select('followerCount')
      });
    } else {
      console.log('POST /follow: Already following, no changes made');
      res.status(200).json({
        message: 'Already following',
        follower: await User.findById(followerId).select('followingCount'),
        followed: await User.findById(artistId).select('followerCount')
      });
    }
  } catch (error) {
    console.error('POST /follow Error:', error.message);
    res.status(500).json({ message: 'Error following artist', error: error.message });
  }
});

// Unfollow an artist
router.delete('/unfollow', protect, async (req, res) => {
  try {
    const { artistId } = req.body;
    const followerId = req.user.id;

    console.log('DELETE /unfollow: Request received - artistId:', artistId, 'followerId:', followerId);
    if (!mongoose.Types.ObjectId.isValid(artistId)) {
      return res.status(400).json({ message: 'Invalid artist ID' });
    }

    if (followerId === artistId) {
      return res.status(400).json({ message: 'Cannot unfollow yourself' });
    }

    const follower = await User.findById(followerId);
    const followed = await User.findById(artistId);

    if (!follower || !followed || followed.role !== 'artist') {
      return res.status(404).json({ message: 'Artist not found' });
    }

    if (follower.following.includes(artistId)) {
      follower.following = follower.following.filter(id => id.toString() !== artistId);
      follower.followingCount = follower.following.length;
      followed.followers = followed.followers.filter(id => id.toString() !== followerId);
      followed.followerCount = followed.followers.length;
      await follower.save({ validateBeforeSave: false });
      await followed.save({ validateBeforeSave: false });
      console.log('DELETE /unfollow: Updated follower:', follower);
      console.log('DELETE /unfollow: Updated followed:', followed);
      res.status(200).json({
        message: 'Unfollowed successfully',
        follower: await User.findById(followerId).select('followingCount'),
        followed: await User.findById(artistId).select('followerCount')
      });
    } else {
      console.log('DELETE /unfollow: Not following, no changes made');
      res.status(200).json({
        message: 'Not following',
        follower: await User.findById(followerId).select('followingCount'),
        followed: await User.findById(artistId).select('followerCount')
      });
    }
  } catch (error) {
    console.error('DELETE /unfollow Error:', error.message);
    res.status(500).json({ message: 'Error unfollowing artist', error: error.message });
  }
});

module.exports = router;