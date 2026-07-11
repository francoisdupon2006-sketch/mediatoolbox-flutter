import 'dart:convert';
import 'package:http/http.dart' as http;

enum ReformulationTone {
  arrogant('Arrogant (Escanor)'),
  impoli('Impoli'),
  business('Business'),
  professionnel('Professionnel'),
  poli('Poli'),
  commercant('Commerçant');

  final String label;
  const ReformulationTone(this.label);

  String get systemPrompt {
    switch (this) {
      case ReformulationTone.arrogant:
        return 'Reformule la phrase avec un ton extrêmement arrogant et condescendant, '
            'à la manière du personnage Escanor (Seven Deadly Sins) : sûr de lui à l\'excès, '
            'se pense supérieur à tout le monde, parle comme si sa force/intelligence était '
            'incontestable et écrasante. Reste percutant et théâtral, sans être vulgaire.';
      case ReformulationTone.impoli:
        return 'Reformule la phrase de façon impolie et directe, sans aucun filtre de courtoisie, '
            'sans respect des formes de politesse habituelles. Cassant, sec, sans détour.';
      case ReformulationTone.business:
        return 'Reformule la phrase dans un style "business" : orienté résultats, efficace, '
            'avec un vocabulaire corporate/entrepreneurial, direct et stratégique.';
      case ReformulationTone.professionnel:
        return 'Reformule la phrase dans un style professionnel neutre : clair, rigoureux, '
            'précis, sans familiarité, adapté à un contexte de travail formel.';
      case ReformulationTone.poli:
        return 'Reformule la phrase de façon très polie et courtoise, avec des formules de '
            'politesse soignées et un ton respectueux et bienveillant.';
      case ReformulationTone.commercant:
        return 'Reformule la phrase dans un style de commerçant/vendeur : persuasif, '
            'orienté client, mettant en valeur les bénéfices, adapté à la négociation ou à la vente.';
    }
  }
}

class ReformulatorService {
  // IMPORTANT : remplace cette clé par ta propre clé API Gemini
  // (https://aistudio.google.com/app/apikey)
  static const String _apiKey = 'TA_CLE_API_GEMINI_ICI';

  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  Future<String> reformulate(String sentence, ReformulationTone tone) async {
    final uri = Uri.parse('$_endpoint?key=$_apiKey');

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {
              "text":
                  "${tone.systemPrompt}\n\nPhrase originale : \"$sentence\"\n\n"
                  "Donne uniquement la phrase reformulée, sans guillemets, sans explication, sans préambule."
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.9,
        "maxOutputTokens": 300,
      }
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur API Gemini (${response.statusCode}) : ${response.body}');
    }

    final data = jsonDecode(response.body);
    final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];

    if (text == null) {
      throw Exception('Réponse Gemini invalide ou vide.');
    }

    return (text as String).trim();
  }
}
