import 'dart:async';
import 'package:flutter/foundation.dart';
import 'hid_controller.dart';
import 'enums.dart';

class DuckyParserIt {
  final HidController hidController;
  KeyboardLayout _activeLayout = KeyboardLayout.pc;
  
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

  // --- PC Layout Map ---
  static final Map<String, List<int>> _pcKeyMap = {
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
    '~': [MOD_RALT, 0x0C], // AltGr + i (common Windows)
    '` \u0060': [MOD_RALT, 0x2E], // AltGr + ' (common Windows)
  };

  // --- Android/Mobile Layout Map ---
  // Many Android targets default strictly to US QWERTY layout when a BT HID connects.
  // To type Italian payloads correctly, we send the US keycodes for the requested characters.
  static final Map<String, List<int>> _androidKeyMap = {
    // Letters
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

    // Punctuation — ITALIAN layout positions (Italian Android uses Italian HID decoding)
    ' ': [MOD_NONE, 0x2C], '\n': [MOD_NONE, 0x28], '\t': [MOD_NONE, 0x2B],

    // Number row symbols — target uses US QWERTY shifted values for number row
    // EXCEPT: 0x38='-', 0x2D='/'? see notes. '/' is only accessible via numpad.
    '!': [MOD_LSHIFT, 0x1E],   // Shift+1 = ! (same US & Italian)
    '"': [MOD_LSHIFT, 0x34],   // Shift+' = " (US style — Italian " is at Shift+2 but target gives @ there)
    '\$': [MOD_LSHIFT, 0x21],  // Shift+4 = $ (same US & Italian)
    '%': [MOD_LSHIFT, 0x22],   // Shift+5 = % (same US & Italian)
    '&': [MOD_LSHIFT, 0x24],   // Shift+7 = & (US style — confirmed by user: target Shift+7 → &)
    '/': [MOD_LSHIFT, 0x38],  // Shift+0x38 = / — CONFIRMED BY USER!
    '(': [MOD_LSHIFT, 0x26],   // Shift+9 = ( (US style — Italian ( is Shift+8 but target is US here)
    ')': [MOD_LSHIFT, 0x27],   // Shift+0 = ) (US style)
    '=': [MOD_NONE, 0x2E],     // = key (US position, confirmed working)
    '?': [MOD_LSHIFT, 0x2D],   // Shift+' = ? (Italian key 0x2D, confirmed working)
    '^': [MOD_LSHIFT, 0x23],   // Shift+6 = ^ (US style)
    '*': [MOD_LSHIFT, 0x25],   // Shift+8 = * (US style)
    '+': [MOD_LSHIFT, 0x2E],   // Shift+= = + (US style)

    '.': [MOD_NONE, 0x37], ',': [MOD_NONE, 0x36],
    ':': [MOD_LSHIFT, 0x33], ';': [MOD_NONE, 0x33],  // confirmed working
    '-': [MOD_NONE, 0x38],     // 0x38 no-modifier = -  — confirmed working
    '_': [MOD_RALT, 0x38],     // AltGr+0x38 — best guess for _ (to test)

    // Special symbols via AltGr on Italian keyboard
    '@': [MOD_RALT, 0x34],               // AltGr+à = @  (Italian standard)
    '#': [MOD_RALT, 0x33],               // AltGr+ò = #
    '[': [MOD_RALT, 0x2F],               // AltGr+è = [
    ']': [MOD_RALT, 0x30],               // AltGr++ = ]
    '{': [MOD_LSHIFT | MOD_RALT, 0x34], // AltGr+Shift+à = {
    '}': [MOD_LSHIFT | MOD_RALT, 0x33], // AltGr+Shift+ò = }
    '|': [MOD_LSHIFT, 0x35],             // Italian: \ key with shift
    '\\': [MOD_NONE, 0x35],              // Italian backslash
    '<': [MOD_NONE, 0x64],               // Extra European key </>
    '>': [MOD_LSHIFT, 0x64],             // Extra European key </> with shift
    '~': [MOD_RALT, 0x0C],               // AltGr+i (common Italian)


    // Italian accented chars fallback -> base letter keycodes (target likely US QWERTY)
    '\u00E0': [MOD_NONE, 0x04], '\u00E8': [MOD_NONE, 0x08], '\u00E9': [MOD_NONE, 0x08],
    '\u00EC': [MOD_NONE, 0x0C], '\u00F2': [MOD_NONE, 0x12], '\u00F9': [MOD_NONE, 0x18],
  };

  Map<String, List<int>> get _currentKeyMap {
    switch (_activeLayout) {
      case KeyboardLayout.android:   return _androidKeyMap;  // target Android con tastiera US
      case KeyboardLayout.androidIt: return _pcKeyMap;       // target Android con tastiera italiana
      case KeyboardLayout.pc:        return _pcKeyMap;       // target Windows/Mac con tastiera italiana
    }
  }

  static const Map<String, int> specialKeys = {
    'ENTER': 0x28, 'ESCAPE': 0x29, 'BACKSPACE': 0x2A, 'TAB': 0x2B, 'SPACE': 0x2C,
    'CAPSLOCK': 0x39, 'F1': 0x3A, 'F2': 0x3B, 'F3': 0x3C, 'F4': 0x3D, 'F5': 0x3E,
    'F6': 0x3F, 'F7': 0x40, 'F8': 0x41, 'F9': 0x42, 'F10': 0x43, 'F11': 0x44, 'F12': 0x45,
    'PRINTSCREEN': 0x46, 'SCROLLLOCK': 0x47, 'PAUSE': 0x48, 'INSERT': 0x49, 'HOME': 0x4A,
    'PAGEUP': 0x4B, 'DELETE': 0x4C, 'END': 0x4D, 'PAGEDOWN': 0x4E,
    'RIGHT': 0x4F, 'LEFT': 0x50, 'DOWN': 0x51, 'UP': 0x52,
  };

  Future<void> executeScript(String script, {KeyboardLayout layout = KeyboardLayout.pc}) async {
    _activeLayout = layout;
    debugPrint("--- ESECUZIONE SCRIPT (LAYOUT: ${_activeLayout.name.toUpperCase()}) ---");
    List<String> lines = script.split('\n');
    for (String line in lines) {
      if (line.trim().isEmpty) continue;
      await parseLine(line.trim());
    }
  }

  Future<void> parseLine(String line) async {
    List<String> parts = line.split(' ');
    String originalCommand = parts[0];
    String command = originalCommand.toUpperCase();
    // Use originalCommand.length to correctly slice the argument from the original line
    String argument = parts.length > 1 ? line.substring(originalCommand.length + 1) : "";

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
        } else if (argument.isEmpty && originalCommand.length == 1) {
          // Single key command — preserve original case!
          await typeString(originalCommand);
        }
        break;
    }
  }

  Future<void> typeString(String text) async {
    final curMap = _currentKeyMap;
    for (int i = 0; i < text.length; i++) {
      String char = text[i];
      if (curMap.containsKey(char)) {
        List<int> combo = curMap[char]!;
        await hidController.sendKey(combo[0], combo[1]);
        await Future.delayed(const Duration(milliseconds: 10)); // Tiny delay for reliability
      }
    }
  }

  Future<void> sendCombo(int modifier, String key) async {
    int keycode = 0;
    final curMap = _currentKeyMap;
    if (key.length == 1) {
      String lowKey = key.toLowerCase();
      if (curMap.containsKey(lowKey)) {
        keycode = curMap[lowKey]![1];
      }
    } else if (specialKeys.containsKey(key.toUpperCase())) {
      keycode = specialKeys[key.toUpperCase()]!;
    }

    if (keycode != 0) {
      await hidController.sendKey(modifier, keycode);
    }
  }
}
