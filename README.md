<div align="center">
  <img src="https://raw.githubusercontent.com/morterix01/Proximity-Shark/main/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" width="120" alt="Logo">
  <h1>🦈 Proximity Shark</h1>
  <p><b>The Ultimate Bluetooth Classic HID Automation & Injection Suite</b></p>
</div>

---

**Proximity Shark** is a powerful, modern, and sleek Android application engineered for security researchers, penetration testers, and automation enthusiasts. Built on Flutter, it transforms your smartphone into a fully programmable, wireless "BadUSB" terminal.

By leveraging low-level Android Bluetooth HID architecture, Proximity Shark can emulate realistic hardware profiles, natively bind to Host machines (Windows, macOS, Linux) without requiring any client-side drivers, and inject **DuckyScript** payloads stealthily over Bluetooth Classic.

## ✨ Key Features

- **Wireless DuckyScript Injection**: Execute standard Rubber Ducky payloads remotely from your pocket. Perfect for rapid automation, sysadmin tasks, and physical security audits.
- **Dynamic Identity Spoofing (SDP Override)**: Seamlessly alter the broadcasted Bluetooth Device Name and SDP service records to masquerade as benign hardware, avoiding target suspicion.
- **Hierarchical Payload Library**: Organize your script arsenal natively inside the app using a built-in folder management system. Keep payloads sorted by target OS, use-case, or severity.
- **Raw Connection Engine**: Custom native bridging (Kotlin -> Dart) designed specifically to bypass Windows L2CAP "handshake hesitations", guaranteeing instantaneous active HID bindings. 
- **Neon Glassmorphism Interface**: Immersive, fluid, and hacker-friendly UI powered by Flutter Animate, featuring frosted glass layers and cyberpunk-inspired visuals.

## 🚀 How It Works

1. **Spoof**: Open the *Device Identity* dashboard, assign a custom alias (e.g., "Logitech MX Keys"), and hit **GO VISIBLE**.
2. **Pair**: On the target machine, pair the newly discovered Bluetooth Keyboard.
3. **Deploy**: Open the *Library Hub*, select your payload, and execute it wirelessly at multi-threaded HID injection speeds.

## 🛠 Prerequisites for Building
- Android Device (Android 9.0 Pie or above)
- Bluetooth permissions
- Flutter SDK (stable branch)
- JDK 17

## 📜 Disclaimer
*Proximity Shark is developed entirely for educational purposes, legitimate systems administration, and authorized red-team security testing. The developer assumes no liability for malicious use. Stay ethical.*
