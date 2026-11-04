importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyBfOItdvgdBywzmBmgNtKoZwJEJ2M49Qxc",
  authDomain: "gaslink-app-4bfbb.firebaseapp.com",
  projectId: "gaslink-app-4bfbb",
  storageBucket: "gaslink-app-4bfbb.firebasestorage.app",
  messagingSenderId: "257420565332",
  appId: "1:257420565332:web:59b31390146c53661c06c1",
  measurementId: "G-WNRH0RNKXY"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Background message: ', payload);
  const notificationTitle = payload.notification?.title || 'GasLink Alert';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});