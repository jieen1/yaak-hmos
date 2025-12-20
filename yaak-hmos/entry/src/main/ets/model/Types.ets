/**
 * Type definitions for Yaak HarmonyOS Application
 */

// HTTP Method types
export type HttpMethod = 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH' | 'HEAD' | 'OPTIONS';

// Body Type for HTTP requests
export type BodyType = 'none' | 'json' | 'xml' | 'form-data' | 'form-urlencoded' | 'binary' | 'graphql' | 'text';

// Authentication types
export type AuthType = 'none' | 'basic' | 'bearer' | 'api-key' | 'oauth2' | 'inherit';

// Response state
export type ResponseState = 'pending' | 'success' | 'error' | 'cancelled';

// API Key location
export type ApiKeyLocation = 'header' | 'query';
