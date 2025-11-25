import { initializeApp } from "firebase/app";
import { getMessaging, getToken } from "firebase/messaging";

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
export const messaging = getMessaging(app);

// 2. Replace with your Key Pair from Project Settings > Cloud Messaging > Web configuration
const VAPID_KEY = "BF03FtvADQR8PrW4u7iYfaYnZdiU6tsXAxZTPRrVVb9HQ115gpq89FAUmIzp_NFh7PBYO2AW0UbmO-leT5g2V6s"; 
export const requestFcmToken = async () => {
  // 1. Safety Checks
  if (!messaging) {
    console.warn("FCM is disabled (Insecure context or not supported).");
    return null;
  }
  
  if (!('serviceWorker' in navigator)) {
    console.warn("Service Workers are not supported in this browser.");
    return null;
  }

  try {
    
    const permission = await Notification.requestPermission();
    if (permission === 'granted') {
      const token = await getToken(messaging, { vapidKey: VAPID_KEY });
      console.log("FCM Token:", token);
      return token;
    } else {
      console.warn("Notification permission denied");
      return null;
    }
  } catch (error) {
    console.error("Error retrieving FCM token:", error);
    return null; // Return null so Login Page continues smoothly
  }
};