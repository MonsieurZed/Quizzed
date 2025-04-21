// Fichier de configuration Firebase pour l'application web
// Remplacez ces valeurs par celles de votre projet Firebase

const firebaseConfig = {
  apiKey: "AIzaSyDZ-5IDDZH6JAwwLAVKLoTgopdF7EfixoI",
  authDomain: "quizzed-base.firebaseapp.com",
  databaseURL: "https://quizzed-base-default-rtdb.europe-west1.firebasedatabase.app",
  projectId: "quizzed-base",
  storageBucket: "quizzed-base.firebasestorage.app",
  messagingSenderId: "290804717986",
  appId: "1:290804717986:web:e5b0b7e845cb51ee3ffafb",
  measurementId: "G-VKXENK378H",
};
// Initialisation de Firebase une fois que le document est chargé
document.addEventListener("DOMContentLoaded", function () {
  // Initialiser Firebase avec la configuration
  firebase.initializeApp(firebaseConfig);

  // Initialiser Analytics si disponible
  if (firebaseConfig.measurementId) {
    firebase.analytics();
  }

  console.log("Firebase initialized successfully");
});
