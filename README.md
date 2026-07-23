# xCtl

SMS Remote Control for Android. Control any Android device remotely by sending SMS commands from authorized phone numbers -- no internet connection required.

## Features

- 50+ SMS commands: LOCATION, CAMERA, LOCK, WIPE, SMS, CALL, WiFi, Bluetooth, files, clipboard, shell, and more
- Whitelist-based security -- only authorized numbers can send commands
- Telegram bot integration for auto-uploading captured media
- Device Admin API support for privileged operations (lock, wipe, password)
- Full command execution logs
- Telegram Mini App companion for download, command reference, and device linking

## All Commands

| Command | Description |
|---------|-------------|
| LOCK | Lock device screen |
| LOCATION | Get GPS location |
| STATUS | Device status info |
| SMS | Send SMS: `xctl SMS +1234567890 message` |
| CALL | Make call: `xctl CALL +1234567890` |
| WIPE | Factory reset (needs Device Admin) |
| PASSWORD | Set lock password: `xctl PASSWORD 1234` |
| CLEARPASSWORD | Remove device password |
| MESSAGE | Show notification: `xctl MESSAGE text` |
| WIFI | WiFi on/off/toggle |
| BLUETOOTH | Bluetooth on/off/toggle |
| DATA | Mobile data on/off/toggle |
| HOTSPOT | Hotspot on/off/toggle |
| BRIGHTNESS | Set brightness 0-255 |
| TIMEOUT | Set screen timeout seconds |
| SCREEN | Screen on/off |
| VOLUME | Set volume 0-15 |
| MUTE | Silence device |
| AIRPLANE | Airplane mode on/off/toggle |
| REBOOT | Reboot device |
| SHUTDOWN | Shutdown device |
| CAMERA | Take photo front/back |
| AUDIO | Record audio: `xctl AUDIO seconds` |
| VIDEO | Record video: `xctl VIDEO seconds` |
| CONTACTS | List contacts |
| CALLS | Recent call log |
| SMSREAD | Read SMS: `xctl SMSREAD count` |
| SMSDELETE | Delete SMS by index |
| FILES | List files: `xctl FILES /path` |
| READ | Read file: `xctl READ /path/to/file` |
| DELETE | Delete file: `xctl DELETE /path` |
| LISTAPPS | List installed apps |
| LAUNCH | Launch app: `xctl LAUNCH pkg.name` |
| STOP | Stop app: `xctl STOP pkg.name` |
| UNINSTALL | Uninstall app: `xctl UNINSTALL pkg` |
| INSTALL | Install from URL: `xctl INSTALL url` |
| SCREENSHOT | Take screenshot |
| CLIPBOARD | Clipboard get/set |
| NOTIFICATION | Send notification |
| FLASH | Flashlight on/off/toggle |
| SHELL | Execute shell command |
| RING | Ring mode normal/silent/vibrate |
| STORAGE | Storage usage info |
| IP | Network IP and WiFi info |
| SIM | SIM and network operator info |
| BATTERY | Battery health and details |
| DND | Do Not Disturb on/off |
| RUNNING | Running processes list |

## Project Structure

```
lib/                    Flutter UI code
  constants.dart        App constants, colors, commands list
  main.dart             App entry point
  models/               State management
  screens/              UI screens
  services/             SMS parsing, command execution

android/                Android native code (Kotlin)
  .../CommandExecutor.kt    Executes parsed commands
  .../CommandService.kt     Foreground service for SMS processing
  .../SmsReceiver.kt        SMS broadcast receiver
  .../TelegramUploader.kt   Telegram media upload + linking
  .../PlatformChannels.kt   Flutter-native bridge
  .../WhitelistManager.kt   Authorized number management

telegram-bot/           Telegram bot server (Node.js)
  index.js              Express server, webhook handler, API routes
  db.js                 JSON-based storage for link codes
  public/               Telegram Mini App frontend
    index.html, style.css, app.js
```

## Building the APK

```bash
flutter build apk --release
```

## Telegram Bot

The `telegram-bot/` directory contains a Node.js server that handles bot commands (`/start`, `/link`, `/help`) and serves the Telegram Mini App.

Deploy on Render:
1. Push to GitHub
2. Create a Web Service on Render
3. Set root directory to `telegram-bot`
4. Add env vars: `TELEGRAM_BOT_TOKEN`, `WEBHOOK_URL`, `APK_DOWNLOAD_URL`

Resources:

- Web: [x-prime.dev](https://x-prime.dev)
- Bot: [@xctlbot_bot](https://t.me/xctlbot_bot)

## License

Use responsibly. Only authorize numbers you trust.
