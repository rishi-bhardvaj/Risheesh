import * as fs from 'fs';
import * as path from 'path';

// Minimal zero-dependency bundler script copying and packaging dist assets
const srcDir = 'src';
const distDir = 'dist';

if (!fs.existsSync(distDir)) {
  fs.mkdirSync(distDir, { recursive: true });
}

// Copy manifest.json
fs.copyFileSync('manifest.json', path.join(distDir, 'manifest.json'));

// Copy HTML files
fs.copyFileSync(path.join(srcDir, 'popup', 'popup.html'), path.join(distDir, 'popup.html'));
fs.copyFileSync(path.join(srcDir, 'options', 'options.html'), path.join(distDir, 'options.html'));

// Build background.js
const bgScript = `
// Career OS Extension Background Bundle
import { detectPageType } from './platforms.js';
import { PolicyGate } from './policy.js';

chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: 'career_os_send_selection',
    title: 'Send selection to Career OS',
    contexts: ['selection'],
  });

  chrome.contextMenus.create({
    id: 'career_os_save_link',
    title: 'Save job link to Career OS',
    contexts: ['page', 'link'],
  });
});
`;
fs.writeFileSync(path.join(distDir, 'background.js'), bgScript);
fs.writeFileSync(path.join(distDir, 'content.js'), '// Career OS Content Script');

console.log('Extension build completed successfully into dist/');
