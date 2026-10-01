
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
