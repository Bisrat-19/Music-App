const Song = require('../models/Song');

exports.uploadSong = async (req, res) => {
  try {
    const { title, genre, description, artistId } = req.body;
    const audioFile = req.files['audio'] ? req.files['audio'][0] : null;
    const coverImage = req.files['coverImage'] ? req.files['coverImage'][0] : null;

    if (!audioFile) {
      return res.status(400).json({ message: 'Audio file is required' });
    }

    const song = new Song({
      title,
      genre,
      description,
      artistId,
      audioPath: audioFile.path,
      coverImagePath: coverImage ? coverImage.path : null,
    });

    await song.save();

    res.status(201).json({ message: 'Track uploaded successfully', song });
  } catch (error) {
    res.status(500).json({ message: 'Error uploading track', error: error.message });
  }
};