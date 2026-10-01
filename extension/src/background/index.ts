import { detectPageType } from '../shared/platforms.js';
import { PolicyGate } from './policy.js';
import { OutboxQueue } from './queue.js';

const outbox = new OutboxQueue();

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

chrome.contextMenus.onClicked.addListener((info, tab) => {
  if (!tab?.url) return;
  const page = detectPageType(tab.url);

  if (info.menuItemId === 'career_os_send_selection' && info.selectionText) {
    outbox.enqueue({
      id: crypto.randomUUID(),
      url: tab.url,
      payload: {
        source: 'manual_selection',
        pageUrl: tab.url,
        platform: page.platform,
        pageType: page.pageType,
        selectionText: info.selectionText.substring(0, 20000),
      },
      attempts: 0,
      createdAt: Date.now(),
    });
  } else if (info.menuItemId === 'career_os_save_link') {
    outbox.enqueue({
      id: crypto.randomUUID(),
      url: info.linkUrl || tab.url,
      payload: {
        source: page.platform,
        url: info.linkUrl || tab.url,
        title: tab.title || '',
      },
      attempts: 0,
      createdAt: Date.now(),
    });
  }
});
