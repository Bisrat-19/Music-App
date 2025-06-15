const express = require('express');
const router = express.Router();
const User = require('../models/User');
const protect = require('../middleware/authMiddleware');
const multer = require('multer');
const path = require('path');

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

// Fetch all artists or search by query (public endpoint)
router.get('/', async (req, res) => {
  try {
    const query = req.query.query || ''; // Default to empty string if no query
    const artists = await User.find(
      query
        ? { role: 'artist', fullName: { $regex: query, $options: 'i' } }
        : { role: 'artist' }
    ).select('fullName profileImagePath');
    const artistsWithDetails = artists.map(artist => ({
      _id: artist._id,
      fullName: artist.fullName,
      avatarPath: artist.profileImagePath || null,
    }));
    res.status(200).json(artistsWithDetails);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching artists', error: error.message });
  }
});

// Fetch artist by ID (public endpoint)
router.get('/:id', async (req, res) => {
  try {
    const artist = await User.findOne({ _id: req.params.id, role: 'artist' }).select('fullName profileImagePath followerCount');
    if (!artist) {
      return res.status(404).json({ message: 'Artist not found' });
    }
    const artistDetails = {
      _id: artist._id,
      fullName: artist.fullName,
      avatarPath: artist.profileImagePath || null,
      followerCount: artist.followerCount,
    };
    res.status(200).json(artistDetails);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching artist', error: error.message });
  }
});

// Update artist avatar (protected endpoint)
router.put('/:id/avatar', protect, upload.single('avatar'), async (req, res) => {
  try {
    const artistId = req.params.id;
    const avatarPath = req.file ? `/uploads/profile/${req.file.filename}` : null;

    console.log('Uploaded avatar file:', req.file);
    if (!avatarPath) {
      return res.status(400).json({ message: 'No image uploaded' });
    }

    const updatedArtist = await User.findByIdAndUpdate(
      artistId,
      { profileImagePath: avatarPath },
      { new: true, select: 'fullName profileImagePath' }
    );
    if (!updatedArtist || updatedArtist.role !== 'artist') {
      return res.status(404).json({ message: 'Artist not found' });
    }

    res.status(200).json(updatedArtist);
  } catch (error) {
    console.error('Error updating artist avatar:', error);
    res.status(500).json({ message: 'Error updating artist avatar', error: error.message });
  }
});

module.exports = router;