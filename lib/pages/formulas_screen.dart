import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'formula_view_screen.dart';

class FormulasScreen extends StatefulWidget {
  const FormulasScreen({super.key});
  @override
  State<FormulasScreen> createState() => _FormulasScreenState();
}

class _FormulasScreenState extends State<FormulasScreen> {
  String? selectedTag;
  final List<Map<String, dynamic>> formulas = [
    {
      'title': 'Квадратное уравнение',
      'formula': 'x = (-b ± √(b² - 4ac)) / (2a)',
      'description': 'Используется для решения уравнений вида ax² + bx + c = 0',
      'latexFormula': r'x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}',
      'fullDescription': 'Квадратное уравнение - это уравнение вида ax² + bx + c = 0, '
          'где a, b и c - числовые коэффициенты, причём a ≠ 0. '
          'Формула позволяет найти значения x, при которых уравнение обращается в тождество.',
      'imageUrl': 'https://example.com/quadratic.jpg',
      'tags': ['Алгебра', 'Уравнения']
    },
    {
      'title': 'Площадь круга',
      'formula': 'S = πr²',
      'description': 'где r - радиус круга',
      'latexFormula': r'S = \pi r^2',
      'fullDescription': 'Формула площади круга выражает зависимость между радиусом круга и его площадью. '
          'Здесь π (пи) - математическая константа, приблизительно равная 3.14159.',
      'imageUrl': 'https://xn----7sbb0bbbgbbtdgb0a2ao4ll4d.xn--p1ai/wp-content/uploads/2023/09/%D1%80%D0%B0%D0%B4%D0%B8%D1%83%D1%81.jpg',
      'tags': ['Геометрия', 'Фигуры', 'Площадь']
    },
    {
      'title': 'Теорема Пифагора',
      'formula': 'a² + b² = c²',
      'description': 'где c - гипотенуза, a и b - катеты',
      'latexFormula': r'a^2 + b^2 = c^2',
      'fullDescription': 'Теорема Пифагора утверждает, что в прямоугольном треугольнике квадрат длины гипотенузы равен сумме квадратов длин катетов. '
          'Это фундаментальное свойство евклидовой геометрии.',
      'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d2/Pythagorean.svg/1200px-Pythagorean.svg.png',
      'tags': ['Геометрия', 'Треугольники']
    },
    {
      'title': 'Закон Ома для участка цепи',
      'formula': 'I = U/R',
      'description': 'I - сила тока [А], U - напряжение [В], R - сопротивление [Ом]',
      'latexFormula': r'I = \frac{U}{R}',
      'fullDescription': 'Закон Ома для участка цепи описывает соотношение между силой тока, напряжением и сопротивлением. '
          'Он гласит, что сила тока в проводнике прямо пропорциональна напряжению и обратно пропорциональна сопротивлению.',
      'imageUrl': 'https://eltehhelp.xyz/wp-content/uploads/2019/07/image-10.png',
      'tags': ['Физика', 'Электричество']
    },
  ];

  Set<String> get allTags {
    Set<String> tags = {};
    for (var formula in formulas) {
      tags.addAll(List<String>.from(formula['tags']));
    }
    return tags;
  }

  List<Map<String, dynamic>> get filteredFormulas {
    if (selectedTag == null) return formulas;
    return formulas.where((formula) => 
      List<String>.from(formula['tags']).contains(selectedTag)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Формулы'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: const Text('Все'),
                    selected: selectedTag == null,
                    onSelected: (bool selected) {
                      setState(() {
                        selectedTag = null;
                      });
                    },
                  ),
                ),
                ...allTags.map((tag) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(tag),
                    selected: selectedTag == tag,
                    onSelected: (bool selected) {
                      setState(() {
                        selectedTag = selected ? tag : null;
                      });
                    },
                  ),
                )).toList(),
              ],
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: filteredFormulas.length,
        itemBuilder: (context, index) {
          final formula = filteredFormulas[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FormulaViewScreen(
                    title: formula['title']!,
                    formula: formula['formula']!,
                    description: formula['fullDescription']!,
                    imageUrl: formula['imageUrl'] ?? '',
                    latexFormula: formula['latexFormula']!,
                  ),
                ),
              );
            },
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formula['title']!,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formula['formula']!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formula['description']!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: List<String>.from(formula['tags']).map((tag) =>
                        Chip(
                          label: Text(tag),
                          backgroundColor: Colors.grey[1000],
                        )
                      ).toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}