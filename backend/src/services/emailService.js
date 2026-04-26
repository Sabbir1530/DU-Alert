const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

/**
 * Send an email.
 */
const sendEmail = async (to, subject, html) => {
  const recipients = (Array.isArray(to) ? to : [to])
    .map((v) => String(v || '').trim())
    .filter(Boolean);

  if (recipients.length === 0) return;

  const mail = {
    from: `"DU Alert" <${process.env.EMAIL_USER}>`,
    subject,
    html,
  };

  if (recipients.length === 1) {
    mail.to = recipients[0];
  } else {
    // Use BCC so recipients do not see each other's emails.
    mail.to = process.env.EMAIL_USER;
    mail.bcc = recipients.join(',');
  }

  await transporter.sendMail(mail);
};

module.exports = { sendEmail };
