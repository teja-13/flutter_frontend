const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true, maxlength: 100 },
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  password: { type: String, required: true },
  createdAt: { type: Date, default: Date.now },
  weatherSearchHistory: [{  // ✅ Added opening curly brace
    city: { type: String, required: true },
    searchedAt: { type: Date, default: Date.now }
  }]  // ✅ Added closing bracket
});

// Method to add to weather search history, keeping maximum 3 entries
userSchema.methods.addWeatherSearch = function(city) {
  this.weatherSearchHistory.unshift({ city, searchedAt: new Date() });
  if (this.weatherSearchHistory.length > 3) {
    this.weatherSearchHistory.pop();
  }
};

module.exports = mongoose.model('User', userSchema);
