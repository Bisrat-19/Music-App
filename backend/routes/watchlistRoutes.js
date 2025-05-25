const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Song = require('../models/Song');
const authMiddleware = require('../middleware/authMiddleware');

// Fetch watchlist for the authenticated user
router.get('/', authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).populate('watchlist');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    const watchlistWithDetails = await Promise.all(user.watchlist.map(async (song) => {
      let artistName = 'Unknown Artist';
      if (song.artistId) {
        const artist = await User.findById(song.artistId);
        artistName = artist ? artist.fullName : 'Unknown Artist';
      }
      let duration = song.duration;
      if (!duration || typeof duration !== 'number') {
        duration = null; // Return null instead of "N/A"
      }
      return {
        _id: song._id,
        title: song.title,
        artistName: artistName,
        coverImagePath: song.coverImagePath || null,
        audioPath: song.audioPath,
        duration: duration,
      };
    }));
    res.status(200).json(watchlistWithDetails);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching watchlist', error: error.message });
  }
});

// Add a song to watchlist
router.post('/', authMiddleware, async (req, res) => {
  try {
    const { songId } = req.body;
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    const song = await Song.findById(songId);
    if (!song) {
      return res.status(404).json({ message: 'Song not found' });
    }
    if (!user.watchlist.includes(songId)) {
      user.watchlist.push(songId);
      await user.save();
    }
    // Repopulate and return updated watchlist
    const updatedUser = await User.findById(req.user.id).populate('watchlist');
    const updatedWatchlist = await Promise.all(updatedUser.watchlist.map(async (song) => {
      let artistName = 'Unknown Artist';
      if (song.artistId) {
        const artist = await User.findById(song.artistId);
        artistName = artist ? artist.fullName : 'Unknown Artist';
      }
      let duration = song.duration;
      if (!duration || typeof duration !== 'number') {
        duration = null; // Return null instead of "N/A"
      }
      return {
        _id: song._id,
        title: song.title,
        artistName: artistName,
        coverImagePath: song.coverImagePath || null,
        audioPath: song.audioPath,
        duration: duration,
      };
    }));
    res.status(200).json({ message: 'Added to watchlist', watchlist: updatedWatchlist });
  } catch (error) {
    res.status(500).json({ message: 'Error adding to watchlist', error: error.message });
  }
});

// Remove a song from watchlist
router.delete('/:songId', authMiddleware, async (req, res) => {
  try {
    const { songId } = req.params;
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    user.watchlist = user.watchlist.filter(id => id.toString() !== songId);
    await user.save();
    // Repopulate and return updated watchlist
    const updatedUser = await User.findById(req.user.id).populate('watchlist');
    const updatedWatchlist = await Promise.all(updatedUser.watchlist.map(async (song) => {
      let artistName = 'Unknown Artist';
      if (song.artistId) {
        const artist = await User.findById(song.artistId);
        artistName = artist ? artist.fullName : 'Unknown Artist';
      }
      let duration = song.duration;
      if (!duration || typeof duration !== 'number') {
        duration = null; // Return null instead of "N/A"
      }
      return {
        _id: song._id,
        title: song.title,
        artistName: artistName,
        coverImagePath: song.coverImagePath || null,
        audioPath: song.audioPath,
        duration: duration,
      };
    }));
    res.status(200).json({ message: 'Removed from watchlist', watchlist: updatedWatchlist });
  } catch (error) {
    res.status(500).json({ message: 'Error removing from watchlist', error: error.message });
  }
});

module.exports = router;