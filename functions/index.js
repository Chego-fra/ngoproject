const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

const mailTransport = nodemailer.createTransport({
  host: "sandbox.smtp.mailtrap.io",
  port: 587,
  auth: {
    user: functions.config().mailtrap.user,
    pass: functions.config().mailtrap.pass,
  },
});

exports.sendNewEventNotification = functions.firestore
  .document("events/{eventId}")
  .onCreate(async (snap, context) => {
    const event = snap.data();
    if (!event) return null;

    const eventDateStr = event.date?.toDate?.().toDateString?.() || "soon";

    const usersSnapshot = await admin.firestore()
      .collection("users")
      .where("role", "==", "volunteer") // Check for spelling again
      .get();

    const recipients = usersSnapshot.docs
      .map((doc) => doc.data().email)
      .filter(Boolean);

    if (recipients.length === 0) {
      console.log("No volunteer emails found.");
      return null;
    }

    const mailOptions = {
      from: "\"NGO Platform\" <noreply@yourapp.com>",
      to: recipients.join(","),
      subject: `New Event: ${event.title}`,
      text: `Hello Volunteer,\n\nA new event "${event.title}" is scheduled for ${eventDateStr} at ${event.location || "a location near you"}.\n\nSee you there!`,
      html: `<p>Hello Volunteer,</p><p>A new event <strong>"${event.title}"</strong> is scheduled for <b>${eventDateStr}</b> at <i>${event.location || "a location near you"}</i>.</p><p>See you there!</p>`,
    };

    try {
      await mailTransport.sendMail(mailOptions);
      console.log(`Emails sent to ${recipients.length} volunteers.`);
    } catch (error) {
      console.error("Email send failed:", error);
    }

    return null;
  });
