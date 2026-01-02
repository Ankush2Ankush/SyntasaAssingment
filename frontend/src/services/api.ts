/**
 * Axios instance and base API configuration
 */
import axios from 'axios';

// Use relative paths to leverage Vercel proxy (configured in vercel.json)
// This avoids mixed content issues (HTTPS frontend -> HTTP backend)
// In development, Vite proxy handles this
// In production, Vercel proxy handles this
// #region agent log
const envViteApiUrl = import.meta.env.VITE_API_URL;
const isDev = import.meta.env.DEV;
const isProd = import.meta.env.PROD;
const mode = import.meta.env.MODE;
console.log('[DEBUG] VITE_API_URL env value:', envViteApiUrl);
console.log('[DEBUG] Is DEV:', isDev, 'Is PROD:', isProd, 'MODE:', mode);
// #endregion

// CRITICAL FIX: Always use empty string (relative paths) in production
// This forces Vercel proxy usage and avoids mixed content issues
// Even if VITE_API_URL is set, we ignore it in production builds
// Explicitly check production mode to ensure empty string
const API_BASE_URL = (isDev || import.meta.env.MODE === 'development') ? (envViteApiUrl || '') : '';

// #region agent log
console.log('[DEBUG] API_BASE_URL final value (after production check):', API_BASE_URL);
console.log('[DEBUG] Using relative paths in production:', !isDev);
// #endregion

if (import.meta.env.DEV) {
  console.log('Using Vite proxy for API requests');
}

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// #region agent log
// Additional runtime safety check - override if somehow HTTP URL got through
if (typeof window !== 'undefined' && !isDev) {
  const currentProtocol = window.location.protocol;
  const currentBaseURL = api.defaults.baseURL;
  console.log('[DEBUG] Production runtime check - protocol:', currentProtocol, 'baseURL:', currentBaseURL);
  
  // Force empty string in production (should already be empty, but double-check)
  if (currentBaseURL && currentBaseURL.startsWith('http://')) {
    console.log('[DEBUG] Production runtime check - FORCING baseURL to empty (was:', currentBaseURL, ')');
    api.defaults.baseURL = '';
  }
}
// #endregion

// Request interceptor
api.interceptors.request.use(
  (config) => {
    // #region agent log
    // Final safety check - force relative paths in production
    if (!isDev && config.baseURL && config.baseURL.startsWith('http://')) {
      console.log('[DEBUG] Request interceptor - PRODUCTION: Forcing config.baseURL to empty (was:', config.baseURL, ')');
      config.baseURL = '';
    }
    
    const fullUrl = (config.baseURL || '') + (config.url || '');
    console.log('[DEBUG] Request interceptor - baseURL:', config.baseURL, 'url:', config.url, 'fullUrl:', fullUrl);
    console.log('[DEBUG] Request interceptor - isDev:', isDev, 'isProd:', isProd);
    // #endregion
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor
api.interceptors.response.use(
  (response) => {
    return response;
  },
  (error) => {
    console.error('API Error:', error);
    if (error.response) {
      // Server responded with error status
      console.error('Response error:', error.response.status, error.response.data);
    } else if (error.request) {
      // Request made but no response received
      console.error('No response received:', error.request);
      console.error('Is the backend running at', API_BASE_URL, '?');
    } else {
      // Something else happened
      console.error('Error setting up request:', error.message);
    }
    return Promise.reject(error);
  }
);

export default api;

