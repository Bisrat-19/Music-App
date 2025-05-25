const express = require('express');
const router = express.Router();
const Playlist = require('../models/Playlist');
const Song = require('../models/Song');
const User = require('../models/User'); // Added to resolve artist name
const authMiddleware = require('../middleware/authMiddleware');

// Fetch playlists for the authenticated user
router.get('/', authMiddleware, async (req, res) => {
  try {
    const playlists = await Playlist.find({ userId: req.user.id }).populate('songs');
    // Enhance each song with artist name
    const playlistsWithArtist = await Promise.all(playlists.map(async (playlist) => {
      const songsWithArtist = await Promise.all(playlist.songs.map(async (song) => {
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
      return {
        _id: playlist._id,
        name: playlist.name,
        userId: playlist.userId,
        songs: songsWithArtist,
      };
    }));
    res.status(200).json(playlistsWithArtist);
  } catch (error) {
    res.status(500).json({ message: 'Error fetching playlists', error: error.message });
  }
});

// Create a new playlist
router.post('/', authMiddleware, async (req, res) => {
  try {
    const { name } = req.body;
    if (!name) {
      return res.status(400).json({ message: 'Playlist name is required' });
    }
    const playlist = new Playlist({
      name,
      userId: req.user.id,
      songs: [],
    });
    await playlist.save();
    res.status(201).json(playlist);
  } catch (error) {
    res.status(500).json({ message: 'Error creating playlist', error: error.message });
  }
});

// Add a song to a playlist
router.post('/:id/songs', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const { songId } = req.body;
    const playlist = await Playlist.findOne({ _id: id, userId: req.user.id });
    if (!playlist) {
      return res.status(404).json({ message: 'Playlist not found or not owned by you' });
    }
    const song = await Song.findById(songId).populate('artistId');
    if (!song) {
      return res.status(404).json({ message: 'Song not found' });
    }
    if (!playlist.songs.includes(songId)) {
      playlist.songs.push(songId);
      await playlist.save();
    }
    // Repopulate and enhance with artist name
    const updatedPlaylist = await Playlist.findById(id).populate('songs');
    const songsWithArtist = await Promise.all(updatedPlaylist.songs.map(async (song) => {
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
    res.status(200).json({ message: 'Song added to playlist', playlist: { ...updatedPlaylist.toObject(), songs: songsWithArtist } });
  } catch (error) {
    res.status(500).json({ message: 'Error adding song to playlist', error: error.message });
  }
});

// Delete a playlist
router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const playlist = await Playlist.findOneAndDelete({ _id: id, userId: req.user.id });
    if (!playlist) {
      return res.status(404).json({ message: 'Playlist not found or not owned by you' });
    }
    res.status(200).json({ message: 'Playlist deleted' });
  } catch (error) {
    res.status(500).json({ message: 'Error deleting playlist', error: error.message });
  }
});

module.exports = router;