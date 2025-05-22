const express = require('express');
const router = express.Router();
const songController = require('../controllers/songController');
const authMiddleware = require('../middleware/authMiddleware');
const roleMiddleware = require('../middleware/roleMiddleware');
const Song = require('../models/Song');
const multer = require('multer');
const fs = require('fs');
const path = require('path');


// Ensure upload directories exist
const uploadBasePath = path.join(__dirname, '..', 'uploads');
const songsPath = path.join(uploadBasePath, 'songs');
const coversPath = path.join(uploadBasePath, 'covers');

const ensureDirectories = () => {
  if (!fs.existsSync(uploadBasePath)) {
    fs.mkdirSync(uploadBasePath, { recursive: true });
    console.log(`Created directory: ${uploadBasePath}`);
  }
  if (!fs.existsSync(songsPath)) {
    fs.mkdirSync(songsPath, { recursive: true });
    console.log(`Created directory: ${songsPath}`);
  }
  if (!fs.existsSync(coversPath)) {
    fs.mkdirSync(coversPath, { recursive: true });
    console.log(`Created directory: ${coversPath}`);
  }
};

ensureDirectories();

// Configure multer for file uploads (unchanged)
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    if (file.fieldname === 'audio') {
      cb(null, songsPath);
    } else if (file.fieldname === 'coverImage') {
      cb(null, coversPath);
    } else {
      cb(new Error('Invalid file field name'), null);
    }
  },
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}-${file.originalname}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 50 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const audioTypes = ['audio/mpeg', 'audio/wav', 'audio/flac', 'audio/mp4', 'application/octet-stream'];
    const imageTypes = ['image/jpeg', 'image/png', 'image/webp', 'application/octet-stream'];
    if (file.fieldname === 'audio' && !audioTypes.includes(file.mimetype)) {
      return cb(new Error('Invalid audio file type. Only MP3, WAV, FLAC, MP4 are allowed.'));
    }
    if (file.fieldname === 'coverImage' && !imageTypes.includes(file.mimetype)) {
      return cb(new Error('Invalid image file type. Only JPG, PNG, WEBP are allowed.'));
    }
    cb(null, true);
  },
}).fields([{ name: 'audio', maxCount: 1 }, { name: 'coverImage', maxCount: 1 }]);

const uploadErrorHandler = (req, res, next) => {
  upload(req, res, (err) => {
    if (err instanceof multer.MulterError) {
      return res.status(400).json({ message: `Upload error: ${err.message}` });
    } else if (err) {
      return res.status(500).json({ message: `Server error: ${err.message}` });
    }
    next();
  });
};

// Upload song route (unchanged)
router.post(
  '/upload',
  authMiddleware,
  roleMiddleware('artist'),
  uploadErrorHandler,
  songController.uploadSong
);

// Get songs by artist
router.get(
  '/my-songs',
  authMiddleware,
  roleMiddleware('artist'),
  async (req, res) => {
    try {
      const artistId = req.user.id;
      const songs = await Song.find({ artistId }).select('-__v');
      res.status(200).json(songs);
    } catch (error) {
      res.status(500).json({ message: 'Error fetching songs', error: error.message });
    }
  }
);

// Update song title
router.put(
  '/songs/:id',
  authMiddleware,
  roleMiddleware('artist'),
  async (req, res) => {
    try {
      const { id } = req.params;
      const { title } = req.body;
      if (!title) {
        return res.status(400).json({ message: 'Title is required' });
      }
      const song = await Song.findOneAndUpdate(
        { _id: id, artistId: req.user.id },
        { title },
        { new: true, runValidators: true }
      );
      if (!song) {
        return res.status(404).json({ message: 'Song not found or not owned by you' });
      }
      res.status(200).json({ message: 'Song title updated successfully', song });
    } catch (error) {
      res.status(500).json({ message: 'Error updating song', error: error.message });
    }
  }
);

// Delete song
router.delete(
  '/songs/:id',
  authMiddleware,
  roleMiddleware('artist'),
  async (req, res) => {
    try {
      const { id } = req.params;
      const song = await Song.findOne({ _id: id, artistId: req.user.id });
      if (!song) {
        return res.status(404).json({ message: 'Song not found or not owned by you' });
      }
      // Delete files from filesystem
      if (song.audioPath) {
        const audioFilePath = path.join(__dirname, '..', song.audioPath.replace('/uploads/', 'uploads/'));
        if (fs.existsSync(audioFilePath)) {
          fs.unlinkSync(audioFilePath);
        }
      }
      if (song.coverImagePath) {
        const coverFilePath = path.join(__dirname, '..', song.coverImagePath.replace('/uploads/', 'uploads/'));
        if (fs.existsSync(coverFilePath)) {
          fs.unlinkSync(coverFilePath);
        }
      }
      await Song.deleteOne({ _id: id });
      res.status(200).json({ message: 'Song deleted successfully' });
    } catch (error) {
      res.status(500).json({ message: 'Error deleting song', error: error.message });
    }
  }
);

module.exports = router;