function genUUID() {
  // Reference: https://stackoverflow.com/a/2117523/709884
  return ("10000000-1000-4000-8000-100000000000").replace(/[018]/g, s => {
    const c = Number.parseInt(s, 10)
    return (c ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16)
  })
}

function updateTabs(tabId, isOnRemoved) {
  browser.tabs.query({})
  .then((tabs) => {
    let length = tabs.length;

    // onRemoved fires too early and the count is one too many.
    // see https://bugzilla.mozilla.org/show_bug.cgi?id=1396758
    if (isOnRemoved && tabId && tabs.map((t) => { return t.id; }).includes(tabId)) {
      length--;
    }

    var syncTabs = tabs
    .filter((tab) => !tab.url.includes("moz-extension"))
    .map(function(tab) { 
      return {"Title":tab.title, "URL":tab.url, "UUID": genUUID().toUpperCase()};
    });

    var port = browser.runtime.connectNative("syncTabs");
    port.postMessage(syncTabs);
    port.disconnect();

    browser.browserAction.setBadgeText({text: length.toString()});
  });
}


browser.tabs.onRemoved.addListener(
  (tabId) => { updateTabs(tabId, true);
});
browser.tabs.onCreated.addListener(
  (tabId) => { updateTabs(tabId, false);
});

browser.alarms.create("tab-sync-alarm", {
  periodInMinutes: 1
});

browser.alarms.onAlarm.addListener((alarmInfo) => { updateTabs(); });

updateTabs();
