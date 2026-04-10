import { initializeApp } from "firebase/app";
import { getMessaging, getToken, isSupported, onMessage } from "firebase/messaging";

// 1. Firebase config is loaded from environment variables (see .env.example)
const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
let messagingInstance = null;

// 2. VAPID key from environment variables
const normalizeVapidKey = (value) => String(value || '').trim().replace(/^['"]|['"]$/g, '').replace(/\s+/g, '');

const VAPID_KEY = normalizeVapidKey(import.meta.env.VITE_FIREBASE_VAPID_KEY);
export const requestFcmToken = async () => {
  if (typeof window === 'undefined' || typeof navigator === 'undefined') {
    return null;
  }

  if (!window.isSecureContext) {
    console.warn("FCM requires a secure context (HTTPS or localhost).");
    return null;
  }

  if (!('serviceWorker' in navigator) || !('Notification' in window)) {
    console.warn("Required browser APIs for FCM are not supported.");
    return null;
  }

  try {
    const supported = await isSupported();
    if (!supported) {
      console.warn("Firebase Messaging is not supported in this browser.");
      return null;
    }

    if (!messagingInstance) {
      messagingInstance = getMessaging(app);
    }

    if (!VAPID_KEY) {
      console.warn('FCM VAPID key is missing. Check VITE_FIREBASE_VAPID_KEY in the company portal environment.');
      return null;
    }

    if (!/^[A-Za-z0-9_-]+$/.test(VAPID_KEY)) {
      console.warn('FCM VAPID key is malformed. It should be the public Web Push certificate from Firebase Cloud Messaging.');
      return null;
    }

    // Ensure our messaging service worker is registered and used
    const registration = await navigator.serviceWorker.register('/firebase-messaging-sw.js', { scope: '/' });

    const isIos = /iPhone|iPad|iPod/i.test(navigator.userAgent || '');
    const isStandalone = window.matchMedia?.('(display-mode: standalone)')?.matches || window.navigator.standalone === true;
    let permission = Notification.permission;

    if (permission !== 'granted') {
      // On iOS web, prompt only when installed as home-screen app.
      if (isIos && !isStandalone) {
        console.info('iOS web push requires adding app to Home Screen first.');
        return null;
      }

      permission = await Notification.requestPermission();
    }

    if (permission === 'granted') {
      const token = await getToken(messagingInstance, { vapidKey: VAPID_KEY, serviceWorkerRegistration: registration });
      console.log("FCM Token:", token);
      return token;
    } else {
      console.warn("Notification permission not granted");
      return null;
    }
  } catch (error) {
    console.error("Error retrieving FCM token:", error);
    return null; // Return null so Login Page continues smoothly
  }
};

export const subscribeToForegroundMessages = async (onPayload) => {
  if (typeof window === 'undefined' || typeof navigator === 'undefined') {
    return () => {};
  }

  try {
    const supported = await isSupported();
    if (!supported) return () => {};

    if (!messagingInstance) {
      messagingInstance = getMessaging(app);
    }

    const unsubscribe = onMessage(messagingInstance, (payload) => {
      if (typeof onPayload === 'function') {
        onPayload(payload);
      }
    });

    return unsubscribe;
  } catch (error) {
    console.warn('Unable to subscribe to foreground FCM messages:', error);
    return () => {};
  }
};