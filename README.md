# Godot Twitch Alerts
- [Features](#features)
- [Screenshots](#screenshots)
- [Installation](#installation)
  - [OBS Integration](#obs-integration)
  - [Supported file formats](#supported-file-formats)
    - [Images](#images)
    - [Sounds](#sounds)
- [Compiling](#compiling)
  - [Monetary donation alerts](#monetary-donation-alerts)
- [Credits](#credits)

# Features

- Custom images/gifs
- Custom sounds
- Subscription alerts
  - Emote support on subscription messages
- Bit donation alerts
- [Monetary donation alerts](#monetary-donation-alerts)

# Screenshots

<details>
<summary>Welcome screen</summary>

![](https://i.imgur.com/MJXc9Pb.png)
  
</details>

<details>
<summary>Debug alert (No alert image)</summary>

![](https://i.imgur.com/lRxDoSj.png)
  
</details>

<details>
<summary>Debug alert (Alert image)</summary>

![](https://i.imgur.com/EnJRq36.png)
  
</details>

<details>
<summary>Use in OBS</summary>

![](https://i.imgur.com/dpql0ab.png)
  
</details>

# Installation
Head to [releases](https://github.com/ynot01/GodotTwitchAlerts/releases/) and download the latest version

<details>
<summary>Extract GodotTwitchAlerts.zip and run GodotTwitchAlerts.exe</summary>

![](https://i.imgur.com/LQ5iOmn.png)
  
</details>

<details>
<summary>Press O (default) to open the options and get an OAuth2 key from Twitch using the button provided</summary>

![](https://i.imgur.com/PtHkIvK.png)
  
</details>

<details>
<summary>Paste your OAuth token into the OAuth token field</summary>

![](https://i.imgur.com/MaVucGq.png)
  
</details>

<details>
<summary>GodotTwitchAlerts will then automatically connect to Twitch Servers and begin monitoring for bit donations & subscriptions, while downloading Twitch's emotes in the background to the emotes folder</summary>

![](https://i.imgur.com/NdV9O4y.png)
  
</details>

## [OBS](https://github.com/obsproject/obs-studio) Integration

<details>
<summary>Add a Game Capture source</summary>

![](https://i.imgur.com/qwSPNKO.png)
  
</details>

<details>
<summary>Set the specific window to GodotTwitchAlerts and allow transparency</summary>

![](https://i.imgur.com/7sSX2V3.png)
  
</details>

<details>
<summary>Modify/resize the window any way you want</summary>

![](https://i.imgur.com/dpql0ab.png)
  
</details>

## Supported file formats

![](https://i.imgur.com/yzg6c2h.png)

### Images
- `.gif`
- `.png`
- `.jpg`, `.jpeg`
- `.webp`
- `.tga`
- `.bmp`
- `.dds`
- `.exr`
- `.hdr`
- `.svg`, `.svgz` - Untested

### Sounds
- `.mp3`
- `.wav`
- `.ogg`

# Compiling

Compiled with [Godot Engine](https://github.com/godotengine/godot) v3.4.1.stable.[goost](https://github.com/goostengine/goost).official

## Monetary donation alerts

Implementing your own $$$ donation alert should be very simple on the engine's side. All that is needed is to insert an array into the `Main` node's `pending_alerts` table with the following format:

`pending_alerts.insert(pending_alerts.size(), ["ynot01", "A Twitch baby is born! :)", DONATION, 5.0])`

where `"ynot01"` is a string, the author of the donation,

`"A Twitch baby is born :)"` is a string, the accompanying message,

`DONATION` is an enum representing the int `0`,

and `5.0` is a float, the donation amount

The hard part will be setting up a WebSocket or other network implementation to actually get notified by your donation handler with this information. Good luck!

# Credits
[Godot Engine](https://github.com/godotengine/godot/)

[goost](https://github.com/goostengine/goost)

[godot-tts](https://github.com/lightsoutgames/godot-tts)
