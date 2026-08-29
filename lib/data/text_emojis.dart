import 'dart:math';

const List<String> Sad = [
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

const List<String> Happy = [
  '⸜(｡˃ ᵕ ˂ )⸝♡',
  '(˶ˆᗜˆ˵)',
  'ヾ(≧∇≦)ゞ',
  'ദ്ദി ˉ͈̀꒳ˉ͈́ )✧',
  '₍₍⚞(˶˃ ꒳ ˂˶)⚟⁾⁾',
  '◝(ᵔᗜᵔ)◜'
];

String getRandomEmoji(List<String> mood) {
  final random = Random();
  return mood[random.nextInt(mood.length)];
}
