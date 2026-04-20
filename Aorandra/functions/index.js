const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

// Gmail transporter
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "aorandra@gmail.com",
    pass: "cpjenqhlujfpbfih"
  }
});

exports.sendResetCode = onCall(async (request) => {

  const email = request.data.email;

  if (!email) {
    throw new Error("Email is required");
  }

  // generate 6 digit code
  const resetCode = Math.floor(100000 + Math.random() * 900000).toString();

  // save code in Firestore
  await admin.firestore()
    .collection("passwordResetCodes")
    .doc(email)
    .set({
      code: resetCode,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

  // email message
  const mailOptions = {
    from: "Aorandra <aorandra@gmail.com>",
    to: email,
    subject: "Password Reset Code",
    html: `
      <div style="font-family:Arial;padding:20px">
        <h2>Password Reset</h2>
        <p>Your verification code is:</p>
        <h1 style="letter-spacing:5px">${resetCode}</h1>
        <p>This code will expire in 10 minutes.</p>
      </div>
    `
  };

  // send email
  await transporter.sendMail(mailOptions);

  return {
    success: true,
    message: "Reset code sent successfully"
  };

});