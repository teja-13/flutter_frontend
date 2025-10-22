const express = require('express');
const axios = require('axios');
const router = express.Router();
const auth = require('../middleware/auth');
const User = require('../models/User');

router.get('/', auth, async (req, res) => {  // ✅ Added auth middleware
  const city = req.query.city;
  const apiKey = process.env.OPENWEATHER_API_KEY;

  if (!city) return res.status(400).json({ message: "City name is required" });

  const url = `https://api.openweathermap.org/data/2.5/weather?q=${encodeURIComponent(city)}&appid=${apiKey}&units=metric`;

  try {
    const response = await axios.get(url);
    const data = response.data;

    // ✅ Save search to user's history
    const user = await User.findById(req.user.userId);
    if (user) {
      user.addWeatherSearch(city);
      await user.save();
    }

    res.json({
      city: data.name,
      country: data.sys.country,
      temp: data.main.temp,
      feels_like: data.main.feels_like,
      weather: data.weather[0].description,
      humidity: data.main.humidity,
      wind: data.wind.speed
    });
  } catch (err) {
    console.error('Weather API error:', err.message);
    res.status(404).json({ message: 'City not found or error fetching weather' });
  }
});

module.exports = router;
