const { validationResult } = require('express-validator');
const bcrypt = require('bcrypt');
const User = require('../models/User');  // ✅ Keep only one import
const generateToken = require('../utils/generateToken');

const SALT_ROUNDS = parseInt(process.env.BCRYPT_SALT_ROUNDS || '12', 10);

exports.register = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  const { name, email, password } = req.body;

  try {
    const existing = await User.findOne({ email });
    if (existing) return res.status(409).json({ message: 'Email already registered' });

    const hashed = await bcrypt.hash(password, SALT_ROUNDS);
    const user = new User({ name, email, password: hashed });
    await user.save();

    const token = generateToken({ userId: user._id });

    return res.status(201).json({
      message: 'User registered',
      token,
      user: { id: user._id, name: user.name, email: user.email }
    });
  } catch (err) {
    console.error('Register error:', err);
    return res.status(500).json({ message: 'Server error' });
  }
};

exports.login = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  const { email, password } = req.body;

  try {
    const user = await User.findOne({ email });
    if (!user) return res.status(401).json({ message: 'Invalid credentials' });

    const match = await bcrypt.compare(password, user.password);
    if (!match) return res.status(401).json({ message: 'Invalid credentials' });

    const token = generateToken({ userId: user._id });

    return res.json({
      message: 'Logged in',
      token,
      user: { id: user._id, name: user.name, email: user.email }
    });
  } catch (err) {
    console.error('Login error:', err);
    return res.status(500).json({ message: 'Server error' });
  }
};

// Adds a city to the logged-in user's weather search history
exports.addWeatherSearch = async (req, res) => {
  try {
    const userId = req.user.userId;  // ✅ Changed from req.user.id
    const city = req.body.city;

    if (!city) return res.status(400).json({ message: 'City is required' });

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: 'User not found' });

    user.addWeatherSearch(city);
    await user.save();

    res.status(200).json({ 
      message: 'Search added to history', 
      weatherSearchHistory: user.weatherSearchHistory 
    });
  } catch (error) {
    console.error('Add weather search error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Deletes the current authenticated user along with all user data
exports.deleteCurrentUser = async (req, res) => {
  try {
    const userId = req.user.userId;  // ✅ Changed from req.user.id
    await User.findByIdAndDelete(userId);
    res.status(200).json({ message: 'User and all data deleted successfully' });
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};
