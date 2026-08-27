// Opens a real browser window so you can log into Facebook manually (handles 2FA/captcha).
// Close the browser window when you're done logging in - this then writes state.json,
// which you upload as-is to the "states" blob container, blob name "state.json".

const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();

  await page.goto('https://www.facebook.com/login');

  await new Promise((resolve) => page.once('close', resolve));

  await context.storageState({ path: 'state.json' });
  await browser.close();

  console.log('Saved session state to state.json');
})();
