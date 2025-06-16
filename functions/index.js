// server/sendNotification.js
const admin = require("firebase-admin");
const express = require("express");
const bodyParser = require("body-parser");

const serviceAccount = require("./serviceAccountKey.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const app = express();
app.use(bodyParser.json());

app.post("/send", async (req, res) => {
  const {token, title, body, eventId} = req.body;

  const message = {
    token,
    notification: {title, body},
    data: eventId ? {eventId} : {},
  };

  try {
    const response = await admin.messaging().send(message);
    res.status(200).json({success: true, response});
  } catch (error) {
    console.error("Error sending message:", error);
    res.status(500).json({success: false, error: error.message});
  }
});

app.listen(3000, () => console.log("Server running on http://localhost:3000"));
