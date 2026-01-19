// lib/main.dart
// Complete Weather App - Updated to work with your backend
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const WeatherApp());
}

/// ========== CONFIG ==========
/// Replace with your backend URL:
const String BACKEND_URL = 'https://flutter-backend-uaim.onrender.com'; // android emulator
// const String BACKEND_URL = 'http://localhost:5000'; // iOS simulator
// const String BACKEND_URL = 'http://YOUR_IP:5000'; // real device
/// ============================

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(),
      routes: {
        '/auth': (_) => const AuthScreen(),
        '/home': (_) => const HomeScreen(),
        '/profile': (_) => const ProfileScreen(),
      },
    );
  }
}

/// Splash: checks token and routes
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Future<void> checkAuth() async {
    await Future.delayed(const Duration(seconds: 2)); // Splash delay
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    
    if (!mounted) return;
    
    if (token != null && token.isNotEmpty) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  @override
  void initState() {
    super.initState();
    checkAuth();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade400, Colors.blue.shade700],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud, size: 100, color: Colors.white),
                SizedBox(height: 20),
                Text(
                  'Weather App',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                SizedBox(height: 20),
                CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        ),
      );
}

/// Combined Login / Signup screen
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  bool loading = false;
  String message = '';

  void showMessage(String m) => setState(() {
        message = m;
      });

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      loading = true;
      message = '';
    });

    final url = Uri.parse(
        isLogin ? '$BACKEND_URL/api/auth/login' : '$BACKEND_URL/api/auth/register');

    final body = isLogin
        ? {'email': emailCtrl.text.trim(), 'password': passCtrl.text}
        : {
            'name': nameCtrl.text.trim(),
            'email': emailCtrl.text.trim(),
            'password': passCtrl.text
          };

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      final data = json.decode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        final token = data['token'];
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt', token);
          await prefs.setString('user', json.encode(data['user'] ?? {}));
          
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          showMessage('No token received from server.');
        }
      } else {
        final msg = data['message'] ?? (data['errors']?.toString() ?? 'Failed');
        showMessage(msg.toString());
      }
    } catch (e) {
      showMessage('Network error: $e');
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = isLogin ? 'Login' : 'Sign Up';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Card(
            elevation: 6,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(isLogin ? Icons.login : Icons.person_add,
                      size: 60, color: Colors.blue),
                  const SizedBox(height: 16),
                  if (!isLogin)
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().length < 2) ? 'Enter name' : null,
                    ),
                  if (!isLogin) const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? 'Enter valid email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Min 6 chars' : null,
                  ),
                  const SizedBox(height: 18),
                  if (message.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(message,
                                style: TextStyle(color: Colors.red.shade700)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: loading ? null : submit,
                      child: loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(title, style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: loading
                        ? null
                        : () => setState(() {
                              isLogin = !isLogin;
                              message = '';
                            }),
                    child: Text(isLogin
                        ? "Don't have an account? Sign up"
                        : "Already have an account? Login"),
                  )
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Home screen: search for city and show weather from backend
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController cityCtrl = TextEditingController();
  bool loading = false;
  Map<String, dynamic>? weather;
  String error = '';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt');
    await prefs.remove('user');
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/auth');
  }

  Future<void> fetchWeather(String city) async {
    setState(() {
      loading = true;
      error = '';
      weather = null;
    });

    try {
      final token = await getToken();
      if (token == null) {
        setState(() {
          error = 'Not authenticated';
          loading = false;
        });
        return;
      }

      // Call YOUR backend weather endpoint
      final url = Uri.parse('$BACKEND_URL/api/weather?city=${Uri.encodeComponent(city.trim())}');

      final res = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          weather = data;
        });
      } else {
        final body = json.decode(res.body);
        setState(() {
          error = body['message'] ?? 'Failed to fetch weather';
        });
      }
    } catch (e) {
      setState(() {
        error = 'Network error: $e';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Widget weatherCard() {
    if (loading) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      ));
    }
    
    if (error.isNotEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.error, color: Colors.red.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(error, style: TextStyle(color: Colors.red.shade700)),
              ),
            ],
          ),
        ),
      );
    }
    
    if (weather == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_outlined, size: 100, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Search for a city to see weather',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    // Backend returns: city, country, temp, feels_like, weather, humidity, wind
    final city = weather!['city'] ?? '';
    final country = weather!['country'] ?? '';
    final temp = weather!['temp'] ?? 0;
    final feelsLike = weather!['feels_like'] ?? 0;
    final desc = weather!['weather'] ?? '';
    final humidity = weather!['humidity'] ?? 0;
    final wind = weather!['wind'] ?? 0;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$city, $country',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Icon(_getWeatherIcon(desc), size: 80, color: Colors.blue),
          const SizedBox(height: 16),
          Text('${temp.toStringAsFixed(1)} °C',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
          Text(desc, style: const TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoColumn(Icons.thermostat, 'Feels Like',
                  '${feelsLike.toStringAsFixed(1)}°C'),
              _buildInfoColumn(Icons.water_drop, 'Humidity', '$humidity%'),
              _buildInfoColumn(Icons.air, 'Wind', '${wind.toStringAsFixed(1)} m/s'),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _buildInfoColumn(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.blue),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  IconData _getWeatherIcon(String weather) {
    final weatherLower = weather.toLowerCase();
    if (weatherLower.contains('clear')) return Icons.wb_sunny;
    if (weatherLower.contains('cloud')) return Icons.cloud;
    if (weatherLower.contains('rain')) return Icons.umbrella;
    if (weatherLower.contains('snow')) return Icons.ac_unit;
    if (weatherLower.contains('thunder')) return Icons.flash_on;
    return Icons.wb_cloudy;
  }

  @override
  void dispose() {
    cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).pushNamed('/profile');
            },
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
            tooltip: 'Logout',
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: cityCtrl,
                    decoration: InputDecoration(
                      hintText: 'Enter city name',
                      prefixIcon: const Icon(Icons.location_city),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (v) {
                      if (v.trim().isNotEmpty) fetchWeather(v.trim());
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final city = cityCtrl.text.trim();
                    if (city.isNotEmpty) fetchWeather(city);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.search),
                ),
              ],
            ),
          ),
          Expanded(child: SingleChildScrollView(child: weatherCard())),
        ],
      ),
    );
  }
}

/// Profile screen: show user info and search history
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool loading = true;
  Map<String, dynamic>? userProfile;
  String error = '';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt');
  }

  Future<void> loadProfile() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final token = await getToken();
      if (token == null) {
        setState(() {
          error = 'Not authenticated';
          loading = false;
        });
        return;
      }

      final url = Uri.parse('$BACKEND_URL/api/profile/me');
      final res = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          userProfile = data;
        });
      } else {
        final body = json.decode(res.body);
        setState(() {
          error = body['message'] ?? 'Failed to load profile';
        });
      }
    } catch (e) {
      setState(() {
        error = 'Network error: $e';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final token = await getToken();
      if (token == null) return;

      final url = Uri.parse('$BACKEND_URL/api/auth/me');
      final res = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to delete account'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(
                  child: Text(error,
                      style: const TextStyle(color: Colors.red, fontSize: 16)))
              : userProfile == null
                  ? const Center(child: Text('No profile data'))
                  : RefreshIndicator(
                      onRefresh: loadProfile,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.blue,
                                    child: Text(
                                      (userProfile!['name'] ?? '?')[0]
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 40,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    userProfile!['name'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    userProfile!['email'] ?? '',
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Recent Searches',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          if ((userProfile!['weatherSearchHistory'] as List?)
                                  ?.isEmpty ??
                              true)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  'No search history yet',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                            )
                          else
                            ...(userProfile!['weatherSearchHistory'] as List)
                                .map((search) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const Icon(Icons.location_city),
                                  title: Text(search['city'] ?? ''),
                                  subtitle: Text(
                                    _formatDate(search['searchedAt']),
                                  ),
                                ),
                              );
                            }).toList(),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: deleteAccount,
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('Delete Account'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}
