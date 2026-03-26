import { HubConnectionBuilder, LogLevel } from '@microsoft/signalr';

let connection = null;

export function createCompanyRequestsConnection() {
  if (connection) return connection;
  const configuredApiBase = import.meta.env.VITE_API_BASE_URL || import.meta.env.VITE_BACKEND_URL || '';
  const apiBase = configuredApiBase || (typeof window !== 'undefined' ? window.location.origin : 'http://localhost:5158');

  connection = new HubConnectionBuilder()
    .withUrl(apiBase + '/hubs/companyRequests', {
      withCredentials: false,
      accessTokenFactory: () => localStorage.getItem('token') || ''
    })
    .configureLogging(LogLevel.Information)
    .withAutomaticReconnect()
    .build();

  // Helpful debug log to show which URL the client will negotiate with
  console.log('SignalR hub URL:', apiBase + '/hubs/companyRequests');

  return connection;
}

export default { createCompanyRequestsConnection };
