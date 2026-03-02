/* eslint-disable no-undef */
// public/firebase-messaging-sw.js
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

// Initialize the Firebase app in the service worker by passing in the messagingSenderId.
firebase.initializeApp({
  apiKey: "AIzaSyDdKCuYdaY3FuIajayBz-16uJVFDjiDEUM",
  authDomain: "hirebridge-c28e9.firebaseapp.com",
  projectId: "hirebridge-c28e9",
  storageBucket: "hirebridge-c28e9.firebasestorage.app",
  messagingSenderId: "82967259176",
  appId: "1:82967259176:web:adf61b7db83b21cdc6ed1d"
});

// Retrieve an instance of Firebase Messaging so that it can handle background messages.
const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/vite.svg' // Replace with your logo path
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});