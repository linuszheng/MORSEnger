Map<String, String> morseToText = {
  '.-': 'a',
  '-...': 'b',
  '-.-.': 'c',
  '-..': 'd',
  '.': 'e',
  '..-.': 'f',
  '--.': 'g',
  '....': 'h',
  '..': 'i',
  '.---': 'j',
  '-.-': 'k',
  '.-..': 'l',
  '--': 'm',
  '-.': 'n',
  '---': 'o',
  '.--.': 'p',
  '--.-': 'q',
  '.-.': 'r',
  '...': 's',
  '-': 't',
  '..-': 'u',
  '...-': 'v',
  '.--': 'w',
  '-..-': 'x',
  '-.--': 'y',
  '--..': 'z',
  '': '',
};

Map<String, String> textToMorse =
    morseToText.map((key, val) => MapEntry(val, key));

class Translator {
  String textOf(morse) {
    var text = '';
    morse.split('/').forEach((word) {
      word.split(' ').forEach((letter) {
        if (morseToText.containsKey(letter)) {
          text += morseToText[letter];
        } else {
          text += '\u{2753}'; // question mark Unicode
        }
      });
      text += ' ';
    });
    return text;
  }

  String morseOf(text) {
    var morse = '';
    text.split(' ').forEach((word) {
      word.split('').forEach((letter) {
        if (textToMorse.containsKey(letter)) {
          morse += textToMorse[letter];
        } else {
          morse += '/';
        }
        morse += ' ';
      });
      morse += '/';
    });
    return morse;
  }
}
