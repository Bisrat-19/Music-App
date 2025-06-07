const express = require('express');
const router = express.Router();
const User = require('../models/User');

// Fetch all artists or search by query (public endpoint)
router.get('/', async (req, res) => {
  try {
    const query = req.query.query || ''; // Default to empty string if no query
    const artists = await User.find(
      query
        ? { role: 'artist', fullName: { $regex: query, $options: 'i' } }
        : { role: 'artist' }
    ).select('fullName profileImagePath'); // Include profileImagePath if available
    const artistsWithDetails = artists.map(artist => ({
      _id: artist._id,
      fullName: artist.fullName,
      avatarPath: artist.profileImagePath || null, // Map profileImagePath to avatarPath
    }));
    res.status(200).json(artistsWithDetails);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching artists', error: error.message });
  }
});

// Fetch artist by ID (public endpoint)
router.get('/:id', async (req, res) => {
  try {
    const artist = await User.findOne({ _id: req.params.id, role: 'artist' }).select('fullName profileImagePath');
    if (!artist) {
      return res.status(404).json({ message: 'Artist not found' });
    }
    const artistDetails = {
      _id: artist._id,
      fullName: artist.fullName,
      avatarPath: artist.profileImagePath || null, // Map profileImagePath to avatarPath
    };
    res.status(200).json(artistDetails);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching artist', error: error.message });
  }
});

module.exports = router;