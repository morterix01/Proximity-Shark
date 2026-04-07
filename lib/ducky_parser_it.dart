import 'dart:async';
import 'hid_controller.dart';

class DuckyParserIt {
  final HidController hidController;
  
  DuckyParserIt(this.hidController);

  // HID Modifiers
  static const int MOD_NONE = 0;
  static const int MOD_LCTRL = 0x01;
  static const int MOD_LSHIFT = 0x02;
  static const int MOD_LALT = 0x04;
  static const int MOD_LGUI = 0x08;
  static const int MOD_RCTRL = 0x10;
  static const int MOD_RSHIFT = 0x20;
  static const int MOD_RALT = 0x40; // AltGr in IT layout

  // Map of characters to [Modifier, Keycode]
  static final Map<String, List<int>> keyMap = {
    'a': [MOD_NONE, 0x04], 'b': [MOD_NONE, 0x05], 'c': [MOD_NONE, 0x06], 'd': [MOD_NONE, 0x07],
    'e': [MOD_NONE, 0x08], 'f': [MOD_NONE, 0x09], 'g': [MOD_NONE, 0x0A], 'h': [MOD_NONE, 0x0B],
    'i': [MOD_NONE, 0x0C], 'j': [MOD_NONE, 0x0D], 'k': [MOD_NONE, 0x0E], 'l': [MOD_NONE, 0x0F],
    'm': [MOD_NONE, 0x10], 'n': [MOD_NONE, 0x11], 'o': [MOD_NONE, 0x12], 'p': [MOD_NONE, 0x13],
    'q': [MOD_NONE, 0x14], 'r': [MOD_NONE, 0x15], 's': [MOD_NONE, 0x16], 't': [MOD_NONE, 0x17],
    'u': [MOD_NONE, 0x18], 'v': [MOD_NONE, 0x19], 'w': [MOD_NONE, 0x1A], 'x': [MOD_NONE, 0x1B],
    'y': [MOD_NONE, 0x1C], 'z': [MOD_NONE, 0x1D],
    
    'A': [MOD_LSHIFT, 0x04], 'B': [MOD_LSHIFT, 0x05], 'C': [MOD_LSHIFT, 0x06], 'D': [MOD_LSHIFT, 0x07],
    'E': [MOD_LSHIFT, 0x08], 'F': [MOD_LSHIFT, 0x09], 'G': [MOD_LSHIFT, 0x0A], 'H': [MOD_LSHIFT, 0x0B],
    'I': [MOD_LSHIFT, 0x0C], 'J': [MOD_LSHIFT, 0x0D], 'K': [MOD_LSHIFT, 0x0E], 'L': [MOD_LSHIFT, 0x0F],
    'M': [MOD_LSHIFT, 0x10], 'N': [MOD_LSHIFT, 0x11], 'O': [MOD_LSHIFT, 0x12], 'P': [MOD_LSHIFT, 0x13],
    'Q': [MOD_LSHIFT, 0x14], 'R': [MOD_LSHIFT, 0x15], 'S': [MOD_LSHIFT, 0x16], 'T': [MOD_LSHIFT, 0x17],
    'U': [MOD_LSHIFT, 0x18], 'V': [MOD_LSHIFT, 0x19], 'W': [MOD_LSHIFT, 0x1A], 'X': [MOD_LSHIFT, 0x1B],
    'Y': [MOD_LSHIFT, 0x1C], 'Z': [MOD_LSHIFT, 0x1D],

    '1': [MOD_NONE, 0x1E], '2': [MOD_NONE, 0x1F], '3': [MOD_NONE, 0x20], '4': [MOD_NONE, 0x21],
    '5': [MOD_NONE, 0x22], '6': [MOD_NONE, 0x23], '7': [MOD_NONE, 0x24], '8': [MOD_NONE, 0x25],
    '9': [MOD_NONE, 0x26], '0': [MOD_NONE, 0x27],
    
    '!': [MOD_LSHIFT, 0x1E], '"': [MOD_LSHIFT, 0x1F], '\u00A3': [MOD_LSHIFT, 0x20], '\$': [MOD_LSHIFT, 0x21],
    '%': [MOD_LSHIFT, 0x22], '&': [MOD_LSHIFT, 0x23], '/': [MOD_LSHIFT, 0x24], '(': [MOD_LSHIFT, 0x25],
    ')': [MOD_LSHIFT, 0x26], '=': [MOD_LSHIFT, 0x27], '?': [MOD_LSHIFT, 0x2D], '^': [MOD_LSHIFT, 0x35],
    
    ' ': [MOD_NONE, 0x2C], '\n': [MOD_NONE, 0x28], '\t': [MOD_NONE, 0x2B],
    '.': [MOD_NONE, 0x37], ',': [MOD_NONE, 0x36], ':': [MOD_LSHIFT, 0x37], ';': [MOD_LSHIFT, 0x36],
    '-': [MOD_NONE, 0x38], '_': [MOD_LSHIFT, 0x38], '+': [MOD_NONE, 0x30], '*': [MOD_LSHIFT, 0x30],

    '\u00E0': [MOD_NONE, 0x33], '\u00E8': [MOD_NONE, 0x2F], '\u00E9': [MOD_LSHIFT, 0x2F], '\u00EC': [MOD_NONE, 0x2E],
    '\u00F2': [MOD_NONE, 0x34], '\u00F9': [MOD_NONE, 0x31],

    '@': [MOD_RALT, 0x34], '#': [MOD_RALT, 0x33], '[': [MOD_RALT, 0x2F], ']': [MOD_RALT, 0x30],
    '{': [MOD_LSHIFT | MOD_RALT, 0x34], '}': [MOD_LSHIFT | MOD_RALT, 0x33],
    '|': [MOD_LSHIFT, 0x35], '\\': [MOD_NONE, 0x35], '<': [MOD_NONE, 0x64], '>': [MOD_LSHIFT, 0x64],
  };

  static const Map<String, int> specialKeys = {
    'ENTER': 0x28, 'ESCAPE': 0x29, 'BACKSPACE': 0x2A, 'TAB': 0x2B, 'SPACE': 0x2C,
    'CAPSLOCK': 0x39, 'F1': 0x3A, 'F2': 0x3B, 'F3': 0x3C, 'F4': 0x3D, 'F5': 0x3E,
    'F6': 0x3F, 'F7': 0x40, 'F8': 0x41, 'F9': 0x42, 'F10': 0x43, 'F11': 0x44, 'F12': 0x45,
    'PRINTSCREEN': 0x46, 'SCROLLLOCK': 0x47, 'PAUSE': 0x48, 'INSERT': 0x49, 'HOME': 0x4A,
    'PAGEUP': 0x4B, 'DELETE': 0x4C, 'END': 0x4D, 'PAGEDOWN': 0x4E,
    'RIGHT': 0x4F, 'LEFT': 0x50, 'DOWN': 0x51, 'UP': 0x52,
  };

  Future<void> executeScript(String script) async {
    List<String> lines = script.split('\n');
    for (String line in lines) {
      if (line.trim().isEmpty) continue;
      await parseLine(line.trim());
    }
  }

  Future<void> parseLine(String line) async {
    List<String> parts = line.split(' ');
    String command = parts[0].toUpperCase();
    String argument = parts.length > 1 ? line.substring(command.length + 1) : "";

    switch (command) {
      case 'STRING':
        await typeString(argument);
        break;
      case 'DELAY':
        int ms = int.tryParse(argument) ?? 0;
        await Future.delayed(Duration(milliseconds: ms));
        break;
      case 'GUI':
      case 'WINDOWS':
        await sendCombo(MOD_LGUI, argument);
        break;
      case 'CONTROL':
      case 'CTRL':
        await sendCombo(MOD_LCTRL, argument);
        break;
      case 'ALT':
        await sendCombo(MOD_LALT, argument);
        break;
      case 'SHIFT':
        await sendCombo(MOD_LSHIFT, argument);
        break;
      case 'ENTER':
        await hidController.sendKey(MOD_NONE, 0x28);
        break;
      case 'TAB':
        await hidController.sendKey(MOD_NONE, 0x2B);
        break;
      default:
        // Try as a special key
        if (specialKeys.containsKey(command)) {
          await hidController.sendKey(MOD_NONE, specialKeys[command]!);
        } else if (argument.isEmpty && command.length == 1) {
          // Single key command
          await typeString(command);
        }
        break;
    }
  }

  Future<void> typeString(String text) async {
    for (int i = 0; i < text.length; i++) {
      String char = text[i];
      if (keyMap.containsKey(char)) {
        List<int> combo = keyMap[char]!;
        await hidController.sendKey(combo[0], combo[1]);
        await Future.delayed(Duration(milliseconds: 10)); // Tiny delay for reliability
      }
    }
  }

  Future<void> sendCombo(int modifier, String key) async {
    int keycode = 0;
    if (key.length == 1) {
      String lowKey = key.toLowerCase();
      if (keyMap.containsKey(lowKey)) {
        keycode = keyMap[lowKey]![1];
      }
    } else if (specialKeys.containsKey(key.toUpperCase())) {
      keycode = specialKeys[key.toUpperCase()]!;
    }

    if (keycode != 0) {
      await hidController.sendKey(modifier, keycode);
    }
  }
}
