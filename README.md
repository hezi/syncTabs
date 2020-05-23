# syncTabs
Sync your firefox tabs with MobileSafari on iOS.

## Found this usful? 
Follow me on twitter [@jorgewritescode](http://twitter.com/jorgewritescode)

## Installation

1. Make sure you have an iCloud account with safari syncing turned on:
![icloud](https://github.com/hezi/syncTabs/blob/master/readme/icloud.png?raw=true)

2. Make and install the native helper app:
```
cd app
make build
make install
```

This will build the helper app and push a "native messaging" manifest to firefox so it knows how to run our helper.

3. Install the Firefox add-on, located in `./add-on/synctabs-1.0-fx.xpi` (this is a pre-signed copy of the add-on)

Or you can package the add-on yourself, using 
```
cd add-on
zip -r -FS ./syncTabs.xpi * --exclude '*.git*'
```
That will create an **unsigned** add-on. Firefox will refuse to install it until you sign it. It's a very annoying (but short) process you can read about [here](https://extensionworkshop.com/documentation/publish/distribute-pre-release-versions/)

4. Use firefox normally. Tabs will start to appear on your MobileSafari tabs overview screen! ![screenshot](https://github.com/hezi/syncTabs/blob/master/readme/screenshot.png?raw=true)