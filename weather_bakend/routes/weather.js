const express = require('express');
const axios = require('axios');
const router = express.Router();

router.get('/', async (req, res) => {
    const city = req.query.city;
    const apiKey = process.env.OPENWEATHER_API_KEY;  // Store your API key in .env

    if (!city) return res.status(400).json({ message: "City name is required" });

    const url = `https://api.openweathermap.org/data/2.5/weather?q=${encodeURIComponent(city)}&appid=${apiKey}&units=metric`;

    try {
        const response = await axios.get(url);
        const data = response.data;

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
        res.status(404).json({ message: 'City not found or error fetching weather' });
    }
});

module.exports = router;
