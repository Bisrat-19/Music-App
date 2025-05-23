const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/authMiddleware');
const roleMiddleware = require('../middleware/roleMiddleware');
const User = require('../models/User');
const Song = require('../models/Song');

// Fetch all users
router.get('/users', authMiddleware, roleMiddleware('admin'), async (req, res) => {
  try {
    const users = await User.find();
    res.status(200).json(users);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching users', error: error.message });
  }
});

// Delete a user
router.delete('/users/:id', authMiddleware, roleMiddleware('admin'), async (req, res) => {
  try {
    const user = await User.findByIdAndDelete(req.params.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.status(200).json({ message: 'User deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Error deleting user', error: error.message });
  }
});

// Fetch all songs
router.get('/songs', authMiddleware, roleMiddleware('admin'), async (req, res) => {
  try {
    const songs = await Song.find().populate('artistId', 'fullName');
    const songsWithArtistName = songs.map(song => {
      const artist = song.artistId ? song.artistId.toJSON() : null;
      return {
        _id: song._id,
        title: song.title,
        artistId: song.artistId ? song.artistId._id : null, // Keep artistId for reference
        artistName: artist ? artist.fullName : 'Unknown Artist', // Safely access fullName
        genre: song.genre,
      };
    });
    res.status(200).json(songsWithArtistName);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching songs', error: error.message });
  }
});

// Delete a song
router.delete('/songs/:id', authMiddleware, roleMiddleware('admin'), async (req, res) => {
  try {
    const song = await Song.findByIdAndDelete(req.params.id);
    if (!song) {
      return res.status(404).json({ message: 'Song not found' });
    }
    res.status(200).json({ message: 'Song deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Error deleting song', error: error.message });
  }
});

// Fetch total listeners
router.get('/listeners', authMiddleware, roleMiddleware('admin'), async (req, res) => {
  try {
    const totalListeners = await User.countDocuments({ role: 'listener' });
    res.status(200).json({ totalListeners });
  } catch (error) {
    res.status(500).json({ message: 'Error fetching listeners', error: error.message });
  }
});

module.exports = router;