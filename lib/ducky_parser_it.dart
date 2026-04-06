import 'dart:async';
import 'hid_controller.dart';

class DuckyParserIt {
  final HidController hidController;
  
  DuckyParserIt(this.hidController);

  // HID Modifiers
  static const int modNone = 0;
  static const int modLCtrl = 0x01;
  static const int modLShift = 0x02;
  static const int modLAlt = 0x04;
  static const int modLGui = 0x08;
  static const int modRCtrl = 0x10;
  static const int modRShift = 0x20;
  static const int modRAlt = 0x40; // AltGr in IT layout

  // Map of characters to [Modifier, Keycode]
  static final Map<String, List<int>> keyMap = {
    'a': [modNone, 0x04], 'b': [modNone, 0x05], 'c': [modNone, 0x06], 'd': [modNone, 0x07],
    'e': [modNone, 0x08], 'f': [modNone, 0x09], 'g': [modNone, 0x0A], 'h': [modNone, 0x0B],
    'i': [modNone, 0x0C], 'j': [modNone, 0x0D], 'k': [modNone, 0x0E], 'l': [modNone, 0x0F],
    'm': [modNone, 0x10], 'n': [modNone, 0x11], 'o': [modNone, 0x12], 'p': [modNone, 0x13],
    'q': [modNone, 0x14], 'r': [modNone, 0x15], 's': [modNone, 0x16], 't': [modNone, 0x17],
    'u': [modNone, 0x18], 'v': [modNone, 0x19], 'w': [modNone, 0x1A], 'x': [modNone, 0x1B],
    'y': [modNone, 0x1C], 'z': [modNone, 0x1D],
    
    'A': [modLShift, 0x04], 'B': [modLShift, 0x05], 'C': [modLShift, 0x06], 'D': [modLShift, 0x07],
    'E': [modLShift, 0x08], 'F': [modLShift, 0x09], 'G': [modLShift, 0x0A], 'H': [modLShift, 0x0B],
    'I': [modLShift, 0x0C], 'J': [modLShift, 0x0D], 'K': [modLShift, 0x0E], 'L': [modLShift, 0x0F],
    'M': [modLShift, 0x10], 'N': [modLShift, 0x11], 'O': [modLShift, 0x12], 'P': [modLShift, 0x13],
    'Q': [modLShift, 0x14], 'R': [modLShift, 0x15], 'S': [modLShift, 0x16], 'T': [modLShift, 0x17],
    'U': [modLShift, 0x18], 'V': [modLShift, 0x19], 'W': [modLShift, 0x1A], 'X': [modLShift, 0x1B],
    'Y': [modLShift, 0x1C], 'Z': [modLShift, 0x1D],

    '1': [modNone, 0x1E], '2': [modNone, 0x1F], '3': [modNone, 0x20], '4': [modNone, 0x21],
    '5': [modNone, 0x22], '6': [modNone, 0x23], '7': [modNone, 0x24], '8': [modNone, 0x25],
    '9': [modNone, 0x26], '0': [modNone, 0x27],
    
    '!': [modLShift, 0x1E], '"': [modLShift, 0x1F], '\u00A3': [modLShift, 0x20], '\$': [modLShift, 0x21],
    '%': [modLShift, 0x22], '&': [modLShift, 0x23], '/': [modLShift, 0x24], '(': [modLShift, 0x25],
    ')': [modLShift, 0x26], '=': [modLShift, 0x27], '?': [modLShift, 0x2D], '^': [modLShift, 0x35],
    
    ' ': [modNone, 0x2C], '\n': [modNone, 0x28], '\t': [modNone, 0x2B],
    '.': [modNone, 0x37], ',': [modNone, 0x36], ':': [modLShift, 0x37], ';': [modLShift, 0x36],
    '-': [modNone, 0x38], '_': [modLShift, 0x38], '+': [modNone, 0x30], '*': [modLShift, 0x30],

    '\u00E0': [modNone, 0x33], '\u00E8': [modNone, 0x2F], '\u00E9': [modLShift, 0x2F], '\u00EC': [modNone, 0x2E],
    '\u00F2': [modNone, 0x34], '\u00F9': [modNone, 0x31],

    '@': [modRAlt, 0x34], '#': [modRAlt, 0x33], '[': [modRAlt, 0x2F], ']': [modRAlt, 0x30],
    '{': [modLShift | modRAlt, 0x34], '}': [modLShift | modRAlt, 0x33],
    '|': [modLShift, 0x35], '\\': [modNone, 0x35], '<': [modNone, 0x64], '>': [modLShift, 0x64],
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
        await sendCombo(modLGui, argument);
        break;
      case 'CONTROL':
      case 'CTRL':
        await sendCombo(modLCtrl, argument);
        break;
      case 'ALT':
        await sendCombo(modLAlt, argument);
        break;
      case 'SHIFT':
        await sendCombo(modLShift, argument);
        break;
      case 'ENTER':
        await hidController.sendKey(modNone, 0x28);
        break;
      case 'TAB':
        await hidController.sendKey(modNone, 0x2B);
        break;
      default:
        // Try as a special key
        if (specialKeys.containsKey(command)) {
          await hidController.sendKey(modNone, specialKeys[command]!);
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
