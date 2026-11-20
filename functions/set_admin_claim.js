// Run this script from a trusted computer or Firebase Cloud Shell.
// Never include a service-account private key inside the mobile application.
// Usage: node set_admin_claim.js admin@example.com

const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');

async function main() {
  const email = process.argv[2];
  if (!email) {
    throw new Error('Pass the admin email: node set_admin_claim.js admin@example.com');
  }

  initializeApp({ credential: applicationDefault() });
  const user = await getAuth().getUserByEmail(email);
  await getAuth().setCustomUserClaims(user.uid, {
    ...(user.customClaims || {}),
    admin: true,
  });

  console.log(`Admin access granted to ${email}. Sign out and sign in again in the app.`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
