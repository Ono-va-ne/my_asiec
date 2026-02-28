import 'dart:math';

const List<String> textEmojis = [
  '>⌓<｡',
  '(つ .•́ _ʖ •̀.)つ',
  '¯\\_(ツ)_/¯',
  '(´･ω･`)?',
  '(-_-)',
  '(O_o)',
  '(._.)',
  '(>_<)',
  'o(TヘTo)',
  '(つ﹏<。)',
  'ಠ_ಠ',
  'ಥ_ಥ',
  '(・_・;)',
  '╮( ˘ ､ ˘ )╭',
  '(✿˃̣̣̥‸˂̣̣̥᷅ )',
  '(·_·)',
  '(;-;)',
  '(´-ι_-｀)',
  '（◞‸◟）'
];

String getRandomEmoji() {
  final random = Random();
  return textEmojis[random.nextInt(textEmojis.length)];
}