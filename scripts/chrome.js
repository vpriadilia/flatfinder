// Extracts Facebook session state from an already-running, already-logged-in Chrome.
// Before running: close Chrome, then relaunch it with:
//   chrome.exe --remote-debugging-port=9222 --user-data-dir="<your normal profile dir>"
// and make sure you're logged into facebook.com in that window.

const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.connectOverCDP('http://localhost:9222');
  const context = browser.contexts()[0];

  const page = context.pages().find((p) => p.url().includes('facebook.com'))
    ?? await context.newPage();
  if (!page.url().includes('facebook.com')) {
    await page.goto('https://www.facebook.com');
  }

  await context.storageState({ path: 'state.json' });
  await browser.close();

  console.log('Saved session state to state.json');
})();
