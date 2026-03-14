# Supabase Rate Limiter Configuration Guide

## 🚀 Rate Limiter Increase Instructions

### Option 1: Supabase Dashboard (Server-Side) - **RECOMMENDED**

**Steps to increase database rate limits:**

1. **Login to Supabase Dashboard**
   - Go to https://app.supabase.com
   - Select your project: `crfpntlltsgidgsezzoq`

2. **Navigate to Project Settings**
   - Click on **Settings** (bottom left)
   - Go to **API** tab

3. **Configure Rate Limits**
   - Look for **Rate Limiting** section
   - **Increase Request Rate:**
     - Default: 1000 requests/minute
     - Recommended for your app: 5000-10000 requests/minute
   - **Increase Connection Pool:**
     - Default: 10 connections
     - Recommended: 20-50 connections

4. **Apply Custom Headers (if available)**
   - `X-Connection-Pool-Size`: Controls number of concurrent connections
   - `X-Request-Retry-Count`: Number of automatic retries
   - `X-Max-Retries`: Maximum retry attempts

---

### Option 2: Client-Side Configuration (Flutter App)

**Already implemented in your `main.dart`:**

```dart
await Supabase.initialize(
  url: supabaseUrl,
  anonKey: supabaseAnonKey,
  headers: {
    'x-connection-pool-size': '20',
    'x-request-retry-count': '3',
    'x-max-retries': '3',
  },
);
```

**What each setting does:**

- `x-connection-pool-size`: '20' → Maintains 20 concurrent connections
- `x-request-retry-count`: '3' → Retries failed requests 3 times
- `x-max-retries`: '3' → Maximum retry policy

---

### Option 3: Code-Level Optimizations

#### A. Request Batching (Reduce number of requests)

```dart
// Instead of multiple individual queries:
// ❌ INEFFICIENT (3 requests)
final faculty = await supabase.from('faculty').select().eq('uid', uid).single();
final students = await supabase.from('students').select().eq('semester', sem);
final events = await supabase.from('events').select();

// ✅ EFFICIENT (1 request with proper joins)
final data = await supabase
    .from('faculty')
    .select('*, semester(*), events(*)')
    .eq('uid', uid)
    .single();
```

#### B. Caching Strategy

```dart
// Add caching layer to reduce database hits
class CacheManager {
  static final Map<String, CachedData> _cache = {};

  static Future<T> getCachedData<T>(
    String key,
    Future<T> Function() fetchFunction,
    {Duration expiry = const Duration(minutes: 5)},
  ) async {
    if (_cache.containsKey(key)) {
      final cached = _cache[key];
      if (DateTime.now().isBefore(cached.expiresAt)) {
        return cached.data as T;
      }
    }

    final data = await fetchFunction();
    _cache[key] = CachedData(data, DateTime.now().add(expiry));
    return data;
  }

  static void clearCache(String key) => _cache.remove(key);
  static void clearAllCache() => _cache.clear();
}

class CachedData {
  final dynamic data;
  final DateTime expiresAt;
  CachedData(this.data, this.expiresAt);
}
```

#### C. Query Pagination (Process fewer items per request)

```dart
// ✅ OPTIMIZED - Load data in chunks
Future<List<User>> loadStudentsPaginated(int page, int pageSize) async {
  final offset = (page - 1) * pageSize;
  return await supabase
      .from('students')
      .select()
      .range(offset, offset + pageSize - 1);
}
```

---

### Option 4: Supabase Pricing Plan Upgrade

**Free Plan Limits:**

- 1,000 requests/minute
- 10 concurrent connections
- Limited bandwidth

**To Increase Further:**

- Upgrade to **Pro Plan**: $25/month
  - 10,000 requests/minute
  - Increased connection pooling
  - Priority support

- Upgrade to **Enterprise**: Contact sales
  - Unlimited requests/minute
  - Custom rate limiting
  - Dedicated support

---

## 📊 Current Configuration Status

✅ **Your App is Now Configured For:**

- Connection Pool Size: **20**
- Auto-Retries: **3 attempts**
- Max Retries: **3**

---

## 🔧 Advanced Tuning Options

### In Supabase Dashboard:

1. **PostgreSQL Configuration**
   - Go to Settings → Database
   - Adjust `max_connections` (default: 100)
   - Recommended: 150-200 for high-traffic apps

2. **Redis Cache (if available)**
   - Enable connection pooling
   - Increase cache size

3. **Bandwidth Limits**
   - Go to Settings → Billing
   - Check current bandwidth usage
   - Upgrade if needed

---

## ⚡ Best Practices to Reduce Rate Limit Issues

1. **Implement Circuit Breaker Pattern**

   ```dart
   Future<T> executeWithCircuitBreaker<T>(
     Future<T> Function() operation,
   ) async {
     try {
       return await operation();
     } catch (e) {
       if (e.toString().contains('429')) { // Rate limit error
         await Future.delayed(Duration(seconds: 5));
         return executeWithCircuitBreaker(operation);
       }
       rethrow;
     }
   }
   ```

2. **Use Database Triggers for Automation**
   - Offload processing to PostgreSQL instead of app

3. **Implement Request Queuing**
   - Queue requests during high traffic
   - Process serially to stay within limits

4. **Monitor Usage**
   - Check Supabase dashboard analytics
   - Set alerts for approaching limits

---

## 📋 Quick Checklist

- [ ] Login to Supabase Dashboard
- [ ] Navigate to Project Settings → API
- [ ] Increase Rate Limit from 1,000 to 5,000+ req/min
- [ ] Verify connection pool size is set to 20+
- [ ] Test app with `flutter run`
- [ ] Monitor database metrics in Supabase Dashboard
- [ ] Consider upgrading plan if still hitting limits

---

## 🆘 Troubleshooting

**Error: "Rate limit exceeded (429)"**

- Increase limit in Supabase Dashboard
- Implement exponential backoff retry logic
- Reduce concurrent requests

**Error: "Connection limit exceeded"**

- Increase `max_connections` in PostgreSQL settings
- Implement connection pooling
- Close unused connections

**Error: "Timeout during database query"**

- Reduce query complexity
- Add indexes to frequently queried columns
- Implement query caching

---

**Last Updated:** March 11, 2026
