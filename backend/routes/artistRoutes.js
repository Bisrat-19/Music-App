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
    ).select('fullName');
    const artistsWithDetails = artists.map(artist => ({
      _id: artist._id,
      fullName: artist.fullName,
      avatarPath: null, // Add avatarPath if available in your User schema
    }));
    res.status(200).json(artistsWithDetails);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching artists', error: error.message });
  }
});

module.exports = router;