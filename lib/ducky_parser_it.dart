import 'dart:async';
import 'package:flutter/foundation.dart';
import 'hid_controller.dart';
import 'enums.dart';

class DuckyParserIt {
  final HidController hidController;
  KeyboardLayout _activeLayout = KeyboardLayout.pc;

  DuckyParserIt(this.hidController);

  // HID Modifiers
  static const int modNone = 0;
  static const int modLctrl = 0x01;
  static const int modLshift = 0x02;
  static const int modLalt = 0x04;
  static const int modLgui = 0x08;
  static const int modRctrl = 0x10;
  static const int modRshift = 0x20;
  static const int modRalt = 0x40; // AltGr in IT layout

  // --- PC Layout Map ---
  static final Map<String, List<int>> _pcKeyMap = {
    'a': [modNone, 0x04],
    'b': [modNone, 0x05],
    'c': [modNone, 0x06],
    'd': [modNone, 0x07],
    'e': [modNone, 0x08],
    'f': [modNone, 0x09],
    'g': [modNone, 0x0A],
    'h': [modNone, 0x0B],
    'i': [modNone, 0x0C],
    'j': [modNone, 0x0D],
    'k': [modNone, 0x0E],
    'l': [modNone, 0x0F],
    'm': [modNone, 0x10],
    'n': [modNone, 0x11],
    'o': [modNone, 0x12],
    'p': [modNone, 0x13],
    'q': [modNone, 0x14],
    'r': [modNone, 0x15],
    's': [modNone, 0x16],
    't': [modNone, 0x17],
    'u': [modNone, 0x18],
    'v': [modNone, 0x19],
    'w': [modNone, 0x1A],
    'x': [modNone, 0x1B],
    'y': [modNone, 0x1C], 'z': [modNone, 0x1D],

    'A': [modLshift, 0x04],
    'B': [modLshift, 0x05],
    'C': [modLshift, 0x06],
    'D': [modLshift, 0x07],
    'E': [modLshift, 0x08],
    'F': [modLshift, 0x09],
    'G': [modLshift, 0x0A],
    'H': [modLshift, 0x0B],
    'I': [modLshift, 0x0C],
    'J': [modLshift, 0x0D],
    'K': [modLshift, 0x0E],
    'L': [modLshift, 0x0F],
    'M': [modLshift, 0x10],
    'N': [modLshift, 0x11],
    'O': [modLshift, 0x12],
    'P': [modLshift, 0x13],
    'Q': [modLshift, 0x14],
    'R': [modLshift, 0x15],
    'S': [modLshift, 0x16],
    'T': [modLshift, 0x17],
    'U': [modLshift, 0x18],
    'V': [modLshift, 0x19],
    'W': [modLshift, 0x1A],
    'X': [modLshift, 0x1B],
    'Y': [modLshift, 0x1C], 'Z': [modLshift, 0x1D],

    '1': [modNone, 0x1E],
    '2': [modNone, 0x1F],
    '3': [modNone, 0x20],
    '4': [modNone, 0x21],
    '5': [modNone, 0x22],
    '6': [modNone, 0x23],
    '7': [modNone, 0x24],
    '8': [modNone, 0x25],
    '9': [modNone, 0x26], '0': [modNone, 0x27],

    '!': [modLshift, 0x1E],
    '"': [modLshift, 0x1F],
    '\u00A3': [modLshift, 0x20],
    '\$': [modLshift, 0x21],
    '%': [modLshift, 0x22],
    '&': [modLshift, 0x23],
    '/': [modLshift, 0x24],
    '(': [modLshift, 0x25],
    ')': [modLshift, 0x26],
    '=': [modLshift, 0x27],
    '?': [modLshift, 0x2D],
    '^': [modLshift, 0x35],

    ' ': [modNone, 0x2C], '\n': [modNone, 0x28], '\t': [modNone, 0x2B],
    '.': [modNone, 0x37],
    ',': [modNone, 0x36],
    ':': [modLshift, 0x37],
    ';': [modLshift, 0x36],
    '-': [modNone, 0x38],
    '_': [modLshift, 0x38],
    '+': [modNone, 0x30],
    '*': [modLshift, 0x30],

    '\u00E0': [modNone, 0x33],
    '\u00E8': [modNone, 0x2F],
    '\u00E9': [modLshift, 0x2F],
    '\u00EC': [modNone, 0x2E],
    '\u00F2': [modNone, 0x34], '\u00F9': [modNone, 0x31],

    '@': [modRalt, 0x34],
    '#': [modRalt, 0x33],
    '[': [modRalt, 0x2F],
    ']': [modRalt, 0x30],
    '{': [modLshift | modRalt, 0x34], '}': [modLshift | modRalt, 0x33],
    '|': [modLshift, 0x35],
    '\\': [modNone, 0x35],
    '<': [modNone, 0x64],
    '>': [modLshift, 0x64],
    '~': [modRalt, 0x0C], // AltGr + i (common Windows)
    '` \u0060': [modRalt, 0x2E], // AltGr + ' (common Windows)
  };

  // --- Android/Mobile Layout Map ---
  // Many Android targets default strictly to US QWERTY layout when a BT HID connects.
  // To type Italian payloads correctly, we send the US keycodes for the requested characters.
  static final Map<String, List<int>> _androidKeyMap = {
    // Letters
    'a': [modNone, 0x04],
    'b': [modNone, 0x05],
    'c': [modNone, 0x06],
    'd': [modNone, 0x07],
    'e': [modNone, 0x08],
    'f': [modNone, 0x09],
    'g': [modNone, 0x0A],
    'h': [modNone, 0x0B],
    'i': [modNone, 0x0C],
    'j': [modNone, 0x0D],
    'k': [modNone, 0x0E],
    'l': [modNone, 0x0F],
    'm': [modNone, 0x10],
    'n': [modNone, 0x11],
    'o': [modNone, 0x12],
    'p': [modNone, 0x13],
    'q': [modNone, 0x14],
    'r': [modNone, 0x15],
    's': [modNone, 0x16],
    't': [modNone, 0x17],
    'u': [modNone, 0x18],
    'v': [modNone, 0x19],
    'w': [modNone, 0x1A],
    'x': [modNone, 0x1B],
    'y': [modNone, 0x1C], 'z': [modNone, 0x1D],

    'A': [modLshift, 0x04],
    'B': [modLshift, 0x05],
    'C': [modLshift, 0x06],
    'D': [modLshift, 0x07],
    'E': [modLshift, 0x08],
    'F': [modLshift, 0x09],
    'G': [modLshift, 0x0A],
    'H': [modLshift, 0x0B],
    'I': [modLshift, 0x0C],
    'J': [modLshift, 0x0D],
    'K': [modLshift, 0x0E],
    'L': [modLshift, 0x0F],
    'M': [modLshift, 0x10],
    'N': [modLshift, 0x11],
    'O': [modLshift, 0x12],
    'P': [modLshift, 0x13],
    'Q': [modLshift, 0x14],
    'R': [modLshift, 0x15],
    'S': [modLshift, 0x16],
    'T': [modLshift, 0x17],
    'U': [modLshift, 0x18],
    'V': [modLshift, 0x19],
    'W': [modLshift, 0x1A],
    'X': [modLshift, 0x1B],
    'Y': [modLshift, 0x1C], 'Z': [modLshift, 0x1D],

    '1': [modNone, 0x1E],
    '2': [modNone, 0x1F],
    '3': [modNone, 0x20],
    '4': [modNone, 0x21],
    '5': [modNone, 0x22],
    '6': [modNone, 0x23],
    '7': [modNone, 0x24],
    '8': [modNone, 0x25],
    '9': [modNone, 0x26], '0': [modNone, 0x27],

    // ── Whitespace ──────────────────────────────────────────────────────────
    ' ': [modNone, 0x2C], '\n': [modNone, 0x28], '\t': [modNone, 0x2B],

    // ── DATI EMPIRICI CONFERMATI DAI TEST ───────────────────────────────────
    // Il target usa layout IBRIDO: US per i tasti standard, IT per i tasti
    // fisicamente diversi tra US e IT (0x38 e 0x2D).

    // Tasti confermati IT (override italiano):
    '-': [modNone, 0x38], // ✅ CONFERMATO: 0x38 no-mod = -
    '_': [modLshift, 0x38], // ✅ CONFERMATO: Shift+0x38 = _
    '?': [modLshift, 0x2D], // ✅ CONFERMATO: Shift+0x2D = ?
    // Tasti confermati US (comportamento americano):
    ':': [
      modLshift,
      0x33,
    ], // ✅ CONFERMATO: Shift+0x33 = : (tasto punto-e-virgola US)
    '=': [modNone, 0x2E], // ✅ CONFERMATO: 0x2E = = (tasto uguale US)
    '.': [modNone, 0x37], // US: tasto punto
    ',': [modNone, 0x36], // US: tasto virgola
    ';': [modNone, 0x33], // US: 0x33 non-shiftato = ;
    '\'': [modNone, 0x2D], // Italian: 0x2D non-shiftato = ' (apostrofo)
    // ── Simboli fila numerica: il target usa valori SHIFTATI americani ──────
    // (confermato: Shift+7 → & come su US, non / come su IT standard)
    '!': [modLshift, 0x1E], // Shift+1 = ! (uguale su US e IT)
    '"': [modLshift, 0x34], // US: Shift+apostrofo = "
    '\$': [modLshift, 0x21], // Shift+4 = $ (uguale su US e IT)
    '%': [modLshift, 0x22], // Shift+5 = % (uguale)
    '&': [modLshift, 0x24], // ✅ CONFERMATO: Shift+7 = & (comportamento US)
    '(': [modLshift, 0x26], // US: Shift+9 = (
    ')': [modLshift, 0x27], // US: Shift+0 = )
    '+': [modLshift, 0x2E], // US: Shift+= = +
    '*': [modLshift, 0x25], // US: Shift+8 = *
    '^': [modLshift, 0x23], // US: Shift+6 = ^
    // ── SLASH — nessuna via standard funziona su questo target ──────────────
    // Testati e falliti: Shift+7→&, 0x38→-, Shift+0x38→_, numpad→-, AltGr+7→fiasco
    // Ultima opzione non testata: AltGr+tasto-slash (0x38)
    '/': [modRalt, 0x38], // ⚠️ UNTESTED: AltGr+0x38 — ultima opzione rimasta
    // ── Simboli AltGr (layout IT) ───────────────────────────────────────────
    '@': [modRalt, 0x34], // AltGr+à = @
    '#': [modRalt, 0x33], // AltGr+ò = #
    '[': [modRalt, 0x2F], // AltGr+è = [
    ']': [modRalt, 0x30], // AltGr++ = ]
    '{': [modLshift | modRalt, 0x2F], // AltGr+Shift+è = {
    '}': [modLshift | modRalt, 0x30], // AltGr+Shift++ = }
    '\\': [modRalt, 0x31], // AltGr+ù = backslash
    '|': [modLshift, 0x31], // Shift+backslash = |
    '<': [modNone, 0x64], // Tasto europeo extra
    '>': [modLshift, 0x64], // Tasto europeo extra shiftato
    '€': [modRalt, 0x08], // AltGr+E = €
    '~': [modRalt, 0x0C], // AltGr+i (fallback IT)
    // ── Caratteri accentati — fallback al tasto base ─────────────────────────
    '\u00E0': [modNone, 0x04], // à → a
    '\u00E8': [modNone, 0x08], // è → e
    '\u00E9': [modNone, 0x08], // é → e
    '\u00EC': [modNone, 0x0C], // ì → i
    '\u00F2': [modNone, 0x12], // ò → o
    '\u00F9': [modNone, 0x18], // ù → u
  };

  // --- Android IT Layout Map ---
  // Mappatura per target Android con layout fisico della tastiera impostato su ITALIANO.
  // Su Android, molti dei tasti base corrispondono alla tastiera PC, ma la gestione
  // di AltGr (Right Alt) e dei simboli speciali può variare leggermente rispetto a Windows.
  static final Map<String, List<int>> _androidItKeyMap = {
    // Lettere standard
    'a': [modNone, 0x04],
    'b': [modNone, 0x05],
    'c': [modNone, 0x06],
    'd': [modNone, 0x07],
    'e': [modNone, 0x08],
    'f': [modNone, 0x09],
    'g': [modNone, 0x0A],
    'h': [modNone, 0x0B],
    'i': [modNone, 0x0C],
    'j': [modNone, 0x0D],
    'k': [modNone, 0x0E],
    'l': [modNone, 0x0F],
    'm': [modNone, 0x10],
    'n': [modNone, 0x11],
    'o': [modNone, 0x12],
    'p': [modNone, 0x13],
    'q': [modNone, 0x14],
    'r': [modNone, 0x15],
    's': [modNone, 0x16],
    't': [modNone, 0x17],
    'u': [modNone, 0x18],
    'v': [modNone, 0x19],
    'w': [modNone, 0x1A],
    'x': [modNone, 0x1B],
    'y': [modNone, 0x1C], 'z': [modNone, 0x1D],

    'A': [modLshift, 0x04],
    'B': [modLshift, 0x05],
    'C': [modLshift, 0x06],
    'D': [modLshift, 0x07],
    'E': [modLshift, 0x08],
    'F': [modLshift, 0x09],
    'G': [modLshift, 0x0A],
    'H': [modLshift, 0x0B],
    'I': [modLshift, 0x0C],
    'J': [modLshift, 0x0D],
    'K': [modLshift, 0x0E],
    'L': [modLshift, 0x0F],
    'M': [modLshift, 0x10],
    'N': [modLshift, 0x11],
    'O': [modLshift, 0x12],
    'P': [modLshift, 0x13],
    'Q': [modLshift, 0x14],
    'R': [modLshift, 0x15],
    'S': [modLshift, 0x16],
    'T': [modLshift, 0x17],
    'U': [modLshift, 0x18],
    'V': [modLshift, 0x19],
    'W': [modLshift, 0x1A],
    'X': [modLshift, 0x1B],
    'Y': [modLshift, 0x1C], 'Z': [modLshift, 0x1D],

    // Numeri
    '1': [modNone, 0x1E],
    '2': [modNone, 0x1F],
    '3': [modNone, 0x20],
    '4': [modNone, 0x21],
    '5': [modNone, 0x22],
    '6': [modNone, 0x23],
    '7': [modNone, 0x24],
    '8': [modNone, 0x25],
    '9': [modNone, 0x26], '0': [modNone, 0x27],

    // Simboli riga dei numeri (Shift+)
    '!': [modLshift, 0x1E], // Shift + 1
    '"': [modLshift, 0x1F], // Shift + 2
    '\u00A3': [modLshift, 0x20], // Shift + 3 (£)
    '\$': [modLshift, 0x21], // Shift + 4 ($)
    '%': [modLshift, 0x22], // Shift + 5
    '&': [modLshift, 0x23], // Shift + 6
    '/': [
      modLshift,
      0x24,
    ], // Shift + 7 (verrà intercettato da typeString per AltCode)
    '(': [modLshift, 0x25], // Shift + 8
    ')': [modLshift, 0x26], // Shift + 9
    '=': [modLshift, 0x27], // Shift + 0
    '?': [modLshift, 0x2D], // Shift + '
    '^': [modLshift, 0x35], // Shift + ì
    // Whitespace
    ' ': [modNone, 0x2C], '\n': [modNone, 0x28], '\t': [modNone, 0x2B],

    // Punteggiatura
    '.': [modNone, 0x37],
    ',': [modNone, 0x36],
    ':': [modLshift, 0x37],
    ';': [modLshift, 0x36],
    '-': [modNone, 0x38],
    '_': [modLshift, 0x38],
    '+': [modNone, 0x30],
    '*': [modLshift, 0x30],

    // Lettere accentate italiane
    '\u00E0': [modNone, 0x33], // à
    '\u00E8': [modNone, 0x2F], // è
    '\u00E9': [modLshift, 0x2F], // é (Shift+è)
    '\u00EC': [modNone, 0x2E], // ì
    '\u00F2': [modNone, 0x34], // ò
    '\u00F9': [modNone, 0x31], // ù
    // Simboli AltGr (Layout IT Android)
    // Nota: Su Android, a volte l'RALT (AltGr) non attiva tutti i caratteri third-level standard di PC,
    // potrebbe essere necessario esplorare comandi supplementari se questi non funzionano.
    '@': [modRalt, 0x34], // AltGr + ò
    '#': [modRalt, 0x33], // AltGr + à
    '[': [modRalt, 0x2F], // AltGr + è
    ']': [modRalt, 0x30], // AltGr + +
    '{': [
      modLshift | modRalt,
      0x2F,
    ], // AltGr + Shift + è = { (Su Android a volte è diverso, ma solitamente matcha il PC)
    '}': [modLshift | modRalt, 0x30], // AltGr + Shift + + = }
    '|': [modLshift, 0x35], // Shift + \ = |
    '\\': [modNone, 0x35], // Tasto \ (vicino a 1)
    '<': [
      modNone,
      0x64,
    ], // Tasto < (se presente sulla tastiera virtuale/fisica)
    '>': [modLshift, 0x64],
    '~': [modRalt, 0x0C], // AltGr + i (Fallback Windows/Android per tilde)
    '`': [modRalt, 0x2E], // AltGr + ' (Fallback per backtick)
  };

  // --- US International Layout Map ---
  // Mappatura per target con layout US International.
  // Identico a US QWERTY per gli scancode base.
  static final Map<String, List<int>> _usIntlKeyMap = {
    'a': [modNone, 0x04], 'b': [modNone, 0x05], 'c': [modNone, 0x06], 'd': [modNone, 0x07],
    'e': [modNone, 0x08], 'f': [modNone, 0x09], 'g': [modNone, 0x0A], 'h': [modNone, 0x0B],
    'i': [modNone, 0x0C], 'j': [modNone, 0x0D], 'k': [modNone, 0x0E], 'l': [modNone, 0x0F],
    'm': [modNone, 0x10], 'n': [modNone, 0x11], 'o': [modNone, 0x12], 'p': [modNone, 0x13],
    'q': [modNone, 0x14], 'r': [modNone, 0x15], 's': [modNone, 0x16], 't': [modNone, 0x17],
    'u': [modNone, 0x18], 'v': [modNone, 0x19], 'w': [modNone, 0x1A], 'x': [modNone, 0x1B],
    'y': [modNone, 0x1C], 'z': [modNone, 0x1D],
    'A': [modLshift, 0x04], 'B': [modLshift, 0x05], 'C': [modLshift, 0x06], 'D': [modLshift, 0x07],
    'E': [modLshift, 0x08], 'F': [modLshift, 0x09], 'G': [modLshift, 0x0A], 'H': [modLshift, 0x0B],
    'I': [modLshift, 0x0C], 'J': [modLshift, 0x0D], 'K': [modLshift, 0x0E], 'L': [modLshift, 0x0F],
    'M': [modLshift, 0x10], 'N': [modLshift, 0x11], 'O': [modLshift, 0x12], 'P': [modLshift, 0x13],
    'Q': [modLshift, 0x14], 'R': [modLshift, 0x15], 'S': [modLshift, 0x16], 'T': [modLshift, 0x17],
    'U': [modLshift, 0x18], 'V': [modLshift, 0x19], 'W': [modLshift, 0x1A], 'X': [modLshift, 0x1B],
    'Y': [modLshift, 0x1C], 'Z': [modLshift, 0x1D],
    '1': [modNone, 0x1E], '2': [modNone, 0x1F], '3': [modNone, 0x20], '4': [modNone, 0x21],
    '5': [modNone, 0x22], '6': [modNone, 0x23], '7': [modNone, 0x24], '8': [modNone, 0x25],
    '9': [modNone, 0x26], '0': [modNone, 0x27],
    '!': [modLshift, 0x1E], '@': [modLshift, 0x1F], '#': [modLshift, 0x20], '\$': [modLshift, 0x21],
    '%': [modLshift, 0x22], '^': [modLshift, 0x23], '&': [modLshift, 0x24], '*': [modLshift, 0x25],
    '(': [modLshift, 0x26], ')': [modLshift, 0x27],
    ' ': [modNone, 0x2C], '\n': [modNone, 0x28], '\t': [modNone, 0x2B],
    '.': [modNone, 0x37], ',': [modNone, 0x36], ':': [modLshift, 0x33], ';': [modNone, 0x33],
    '-': [modNone, 0x2D], '_': [modLshift, 0x2D], '=': [modNone, 0x2E], '+': [modLshift, 0x2E],
    '[': [modNone, 0x2F], '{': [modLshift, 0x2F], ']': [modNone, 0x30], '}': [modLshift, 0x30],
    '\\': [modNone, 0x31], '|': [modLshift, 0x31], '`': [modNone, 0x35], '~': [modLshift, 0x35],
    '\'': [modNone, 0x34], '"': [modLshift, 0x34], '<': [modLshift, 0x36], '>': [modLshift, 0x37],
    '/': [modNone, 0x38], '?': [modLshift, 0x38],
  };

  Map<String, List<int>> get _currentKeyMap {
    switch (_activeLayout) {
      case KeyboardLayout.android:
        return _androidKeyMap; // target Android con decodifica US QWERTY
      case KeyboardLayout.androidIt:
        return _androidItKeyMap; // target Android con tastiera italiana impostata
      case KeyboardLayout.pc:
        return _pcKeyMap; // target Windows/Mac con tastiera italiana
      case KeyboardLayout.usInternational:
        return _usIntlKeyMap;
    }
  }

  static const Map<String, int> specialKeys = {
    'ENTER': 0x28,
    'ESCAPE': 0x29,
    'BACKSPACE': 0x2A,
    'TAB': 0x2B,
    'SPACE': 0x2C,
    'CAPSLOCK': 0x39,
    'F1': 0x3A,
    'F2': 0x3B,
    'F3': 0x3C,
    'F4': 0x3D,
    'F5': 0x3E,
    'F6': 0x3F,
    'F7': 0x40,
    'F8': 0x41,
    'F9': 0x42,
    'F10': 0x43,
    'F11': 0x44,
    'F12': 0x45,
    'PRINTSCREEN': 0x46,
    'SCROLLLOCK': 0x47,
    'PAUSE': 0x48,
    'INSERT': 0x49,
    'HOME': 0x4A,
    'PAGEUP': 0x4B,
    'DELETE': 0x4C,
    'END': 0x4D,
    'PAGEDOWN': 0x4E,
    'RIGHT': 0x4F,
    'LEFT': 0x50,
    'DOWN': 0x51,
    'UP': 0x52,
  };

  Future<void> executeScript(
    String script, {
    KeyboardLayout layout = KeyboardLayout.pc,
    void Function(double progress)? onProgress,
  }) async {
    _activeLayout = layout;
    debugPrint("--- ESECUZIONE SCRIPT (LAYOUT: ${_activeLayout.name.toUpperCase()}) ---");
    
    List<String> lines = script.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) {
      if (onProgress != null) onProgress(1.0);
      return;
    }

    // Phase 1: Calculate total "weight" for smooth progress
    double totalWeight = 0;
    for (var line in lines) {
      totalWeight += _calculateLineWeight(line.trim());
    }

    // Phase 2: Execute with granular updates
    double currentWeight = 0;
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      await parseLine(line, onProgressStep: (stepWeight) {
        currentWeight += stepWeight;
        if (onProgress != null && totalWeight > 0) {
          onProgress(currentWeight / totalWeight);
        }
      });
    }

    if (onProgress != null) onProgress(1.0);
  }

  double _calculateLineWeight(String line) {
    List<String> parts = line.split(' ');
    if (parts.isEmpty) return 0;
    String command = parts[0].toUpperCase();
    String argument = parts.length > 1 ? line.substring(parts[0].length + 1) : "";

    switch (command) {
      case 'STRING':
        return argument.length.toDouble();
      case 'DELAY':
        int ms = int.tryParse(argument) ?? 0;
        // 1 weight point every 20ms to match typing speed approx
        return ms / 20.0;
      default:
        return 1.0;
    }
  }

  Future<void> parseLine(String line, {void Function(double stepWeight)? onProgressStep}) async {
    List<String> parts = line.split(' ');
    String originalCommand = parts[0];
    String command = originalCommand.toUpperCase();
    String argument = parts.length > 1
        ? line.substring(originalCommand.length + 1)
        : "";

    switch (command) {
      case 'STRING':
        await typeString(argument, onProgressStep: onProgressStep);
        break;
      case 'DELAY':
        int ms = int.tryParse(argument) ?? 0;
        // Granular delay updates
        int steps = (ms / 20).floor();
        int remaining = ms % 20;
        for (int i = 0; i < steps; i++) {
          await Future.delayed(const Duration(milliseconds: 20));
          if (onProgressStep != null) onProgressStep(1.0);
        }
        if (remaining > 0) {
          await Future.delayed(Duration(milliseconds: remaining));
        }
        break;
      case 'GUI':
      case 'WINDOWS':
        await sendCombo(modLgui, argument);
        if (onProgressStep != null) onProgressStep(1.0);
        break;
      case 'CONTROL':
      case 'CTRL':
        await sendCombo(modLctrl, argument);
        if (onProgressStep != null) onProgressStep(1.0);
        break;
      case 'ALT':
        await sendCombo(modLalt, argument);
        if (onProgressStep != null) onProgressStep(1.0);
        break;
      case 'SHIFT':
        await sendCombo(modLshift, argument);
        if (onProgressStep != null) onProgressStep(1.0);
        break;
      case 'ENTER':
        await hidController.sendKey(modNone, 0x28);
        if (onProgressStep != null) onProgressStep(1.0);
        break;
      case 'TAB':
        await hidController.sendKey(modNone, 0x2B);
        if (onProgressStep != null) onProgressStep(1.0);
        break;
      default:
        // Try as a special key
        if (specialKeys.containsKey(command)) {
          await hidController.sendKey(modNone, specialKeys[command]!);
        } else if (argument.isEmpty && originalCommand.length == 1) {
          // Single key command — preserve original case!
          await typeString(originalCommand);
        }
        if (onProgressStep != null) onProgressStep(1.0);
        break;
    }
  }

  Future<void> typeString(String text, {void Function(double stepWeight)? onProgressStep}) async {
    final curMap = _currentKeyMap;
    for (int i = 0; i < text.length; i++) {
      String char = text[i];

      if (curMap.containsKey(char)) {
        List<int> combo = curMap[char]!;
        await hidController.sendKey(combo[0], combo[1]);
        await Future.delayed(
          const Duration(milliseconds: 10),
        ); // Tiny delay for reliability
      }
      
      if (onProgressStep != null) {
        onProgressStep(1.0);
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
