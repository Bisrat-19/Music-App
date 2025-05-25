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

router.post('/users', authMiddleware, roleMiddleware('admin'), async (req, res) => {
  try {
    const { fullName, email, role, password } = req.body;

    if (!fullName || !email || !role || !password) {
      return res.status(400).json({ message: 'Full name, email, role, and password are required' });
    }

    // 🔥 Let Mongoose schema pre('save') hook handle password hashing
    const user = new User({ fullName, email, role, password });

    await user.save();

    res.status(201).json({ message: 'User created successfully', user });
  } catch (error) {
    res.status(500).json({ message: 'Error creating user', error: error.message });
  }
});

// Edit user
router.put('/users/:id', authMiddleware, roleMiddleware('admin'), async (req, res) => {
  try {
    const { fullName, email, role } = req.body;
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { fullName, email, role },
      { new: true, runValidators: true }
    );
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.status(200).json({ message: 'User updated successfully', user });
  } catch (error) {
    res.status(500).json({ message: 'Error updating user', error: error.message });
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
        artistId: song.artistId ? song.artistId._id : null,
        artistName: artist ? artist.fullName : 'Unknown Artist',
        genre: song.genre,
      };
    });
    res.status(200).json(songsWithArtistName);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching songs', error: error.message });
  }
});

// Add new song
router.post('/songs', authMiddleware, roleMiddleware('admin'), async (req, res) => {
  try {
    const { title, genre, description, artistId, audioPath, coverImagePath } = req.body;

    if (!title || !genre || !artistId || !audioPath) {
      return res.status(400).json({ message: 'Title, genre, artistId, and audioPath are required' });
    }

    const song = new Song({
      title,
      genre,
      description: description || '',
      artistId,
      audioPath,
      coverImagePath: coverImagePath || null,
    });

    await song.save();

    res.status(201).json({ message: 'Song created successfully', song });
  } catch (error) {
    res.status(500).json({ message: 'Error creating song', error: error.message });
  }
});

// Edit song
router.put('/songs/:id', authMiddleware, roleMiddleware('admin'), async (req, res) => {
  try {
    const { title, genre } = req.body;

    if (!title || !genre) {
      return res.status(400).json({ message: 'Title and genre are required' });
    }

    const song = await Song.findByIdAndUpdate(
      req.params.id,
      { title, genre },
      { new: true, runValidators: true }
    );

    if (!song) {
      return res.status(404).json({ message: 'Song not found' });
    }

    res.status(200).json({ message: 'Song updated successfully', song });
  } catch (error) {
    res.status(500).json({ message: 'Error updating song', error: error.message });
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
