import { initializeApp } from "firebase/app";
import { getMessaging, getToken, isSupported, onMessage } from "firebase/messaging";

// 1. Replace with your actual Firebase Config from Console
const firebaseConfig = {
  apiKey: "AIzaSyDdKCuYdaY3FuIajayBz-16uJVFDjiDEUM",
  authDomain: "hirebridge-c28e9.firebaseapp.com",
  projectId: "hirebridge-c28e9",
  storageBucket: "hirebridge-c28e9.firebasestorage.app",
  messagingSenderId: "82967259176",
  appId: "1:82967259176:web:adf61b7db83b21cdc6ed1d"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
let messagingInstance = null;

// 2. Replace with your Key Pair from Project Settings > Cloud Messaging > Web configuration
const VAPID_KEY = "BF03FtvADQR8PrW4u7iYfaYnZdiU6tsXAxZTPRrVVb9HQ115gpq89FAUmIzp_NFh7PBYO2AW0UbmO-leT5g2V6s"; 
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