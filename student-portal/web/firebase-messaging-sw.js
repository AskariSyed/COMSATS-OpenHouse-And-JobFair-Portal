// Import the Firebase app and messaging scripts
importScripts("https://www.gstatic.com/firebasejs/9.22.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.22.1/firebase-messaging-compat.js");

const firebaseConfig = {
  apiKey: 'AIzaSyDdKCuYdaY3FuIajayBz-16uJVFDjiDEUM',
    appId: '1:82967259176:web:adf61b7db83b21cdc6ed1d',
    messagingSenderId: '82967259176',
    projectId: 'hirebridge-c28e9',
    authDomain: 'hirebridge-c28e9.firebaseapp.com',
    storageBucket: 'hirebridge-c28e9.firebasestorage.app',
    measurementId: 'G-JDM3F9TTQD',
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);

// Retrieve an instance of Firebase Messaging
const messaging = firebase.messaging();

// Handle background messages (app is minimised or tab is not active)
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message:', payload);

  const title = (payload.notification && payload.notification.title)
    ? payload.notification.title
    : 'Job Fair Portal';
  const body = (payload.notification && payload.notification.body)
    ? payload.notification.body
    : '';

  const options = {
    body: body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data || {},
  };

  return self.registration.showNotification(title, options);
});