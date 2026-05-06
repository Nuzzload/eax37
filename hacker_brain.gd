# hacker_brain.gd
# Autoload HackerBrain
extends Node

enum HackerMood { COLD, THREATENING, AMUSED, IMPATIENT, SATISFIED }
var current_mood: HackerMood = HackerMood.COLD
var message_count: int = 0
var last_topic: String = ""
var last_hacker_response: String = ""

const KEYWORDS = {
	"refus": [
		"non", "jamais", "refuse", "pas question", "stop", "arrête", "laisse moi",
		"fous moi", "fous le camp", "va te faire", "je veux pas", "j'veux pas",
		"pas envie", "m'en fiche", "m'en fous", "je m'en fous", "je m'en fiche",
		"bof", "nan", "nope", "no", "rien à faire", "rien à foutre",
	],
	"accord": [
		"ok", "okay", "oui", "d'accord", "compris", "je vais", "je veux bien",
		"bien", "entendu", "reçu", "vu", "je comprends", "j'ai compris",
		"c'est bon", "ça marche", "je ferai", "je vais faire", "j'y vais",
	],
	"identite": [
		"qui es", "qui t'es", "qui tu es", "qui êtes", "ton nom", "c'est qui",
		"t'es qui", "tu es qui", "ton identité", "tu travailles pour",
		"t'appartiens", "t'es humain", "t'es une ia", "t'es un robot",
	],
	"menace_joueur": [
		"police", "flic", "gendarme", "signaler", "dénoncer", "autorité",
		"avocat", "justice", "tribunal", "porter plainte", "te dénoncer",
		"te signaler", "cybercrime", "interpol", "fbi",
	],
	"pitie": [
		"pitié", "s'il te plait", "s'il vous plait", "je t'en supplie",
		"aide moi", "grâce", "je t'en prie", "par pitié",
	],
	"insulte": [
		"connard", "salaud", "ordure", "bâtard", "enfoiré", "fils de",
		"va te", "ta gueule", "merde", "nique", "con", "idiot", "imbécile",
		"abruti", "crétin", "débile", "psychopathe", "malade","ntm","ta mère",
	],
	"negocie": [
		"combien", "argent", "payer", "deal", "marché", "négoci",
		"proposition", "offre", "si je paie", "rançon",
	],
	"peur": [
		"peur", "effrayé", "terrifié", "paniqué", "stressé", "angoisse",
		"flippe", "je tremble", "j'ai peur", "ça me fait peur",
	],
	"question_pourquoi": [
		"pourquoi moi", "pourquoi tu fais", "pourquoi vous faites",
		"qu'est-ce que j'ai fait", "c'est quoi mon crime", "j'ai rien fait",
		"je mérite pas", "c'est pas juste", "pourquoi",
	],
	"question_info": [
		"c'est quoi", "qu'est-ce que", "comment", "explique", "dis moi",
		"c'est quand", "quoi exactement", "t'as quoi", "vous avez quoi",
		"t'as quoi sur moi", "c'est quoi les preuves",
	],
	"delai": [
		"combien de temps", "délai", "quand", "date limite", "deadline",
		"j'ai le temps", "c'est pour quand", "t'es pressé",
	],
	"defi": [
		"t'es pas capable", "tu mens", "j'y crois pas", "prouve le",
		"montre moi", "bluff", "t'as rien", "tu peux pas", "essaie",
		"vas-y", "je te crois pas", "fais-le", "chiche",
		"tu vas faire quoi", "sinon quoi", "et alors",
		"et après", "tu feras quoi", "qu'est-ce que tu vas faire",
		"ça change quoi", "je m'en tape", "je m'en bats",
		"tu peux rien faire", "t'as aucun pouvoir", "t'es rien",
		"ça m'intéresse pas", "je te crains pas", "j'ai pas peur",
		"rien à perdre", "fais le", "allez", "allez-y",
		"je m'en bas", "m'en bas", "bas les couilles", "couilles",
		"faire quoi si", "tu fais quoi si", "si je dis non",
		"si je refuse", "tu vas faire quoi", "t'as pas les",
		"je doute", "j'en doute", "on s'en fout", "s'en fout",
	],
	"resignation": [
		"ok je fais", "je vais obéir", "je me rends", "j'abandonne",
		"tu as gagné", "t'as raison", "je vais faire ce que tu dis",
		"j'ai pas le choix", "pas le choix",
	],
}

const RESPONSES = {
	"refus": [
		"Tu crois vraiment avoir le choix ?",
		"Intéressant. Je t'enverrai quand même les fichiers. À ta famille d'abord.",
		"Non. C'est mignon.",
		"Tu peux dire non autant que tu veux. Ça ne changera rien.",
		"J'avais prévu que tu dirais ça.",
		"Ta résistance a un coût. Tu ne peux pas te le permettre.",
		"Les gens qui disent non au début finissent toujours par obéir.",
		"Très bien. Je laisse les fichiers se diffuser alors.",
		"Tu réalises ce que tu risques ?",
		"D'accord. Je m'occupe de tes proches en premier.",
		"Parfait. J'avais préparé quelque chose pour cette réponse.",
		"Tu me facilites le travail en fait.",
		"Noted.",
	],
	"accord": [
		"Bien. Continue.",
		"C'est tout ce que je voulais entendre.",
		"Tu apprends vite.",
		"Parfait. Ne traîne pas.",
		"Sage décision.",
		"Je savais que tu comprendrais.",
		"Bien. On avance.",
	],
	"identite": [
		"▓▓▓.",
		"Ce n'est pas une information dont tu as besoin.",
		"Quelqu'un qui sait tout sur toi. Et toi, tu ne sais rien sur moi.",
		"Appelle-moi comme tu veux. Ta situation reste la même.",
		"La question n'est pas qui je suis. La question c'est ce que je sais sur toi.",
		"Tu préfères savoir mon nom ou garder tes secrets ?",
	],
	"menace_joueur": [
		"La police ? Et tu leur montres quoi exactement ?",
		"Vas-y. Appelle-les. Je suis curieux de voir comment tu expliques le reste.",
		"Tu penses qu'ils vont te croire ? Avec ce que j'ai sur toi ?",
		"Toutes les preuves pointent vers toi. Pas vers moi.",
		"J'ai déjà prévu ce scénario. Continue.",
		"Ils vont adorer ce que j'ai préparé pour eux.",
	],
	"pitie": [
		"...",
		"Je ne suis pas là pour compatir.",
		"Tes émotions ne m'intéressent pas.",
		"Ce n'est pas personnel. C'est une transaction.",
		"Garde ton énergie. Tu en auras besoin.",
	],
	"insulte": [
		"Tu te sentiras mieux après ?",
		"Continue. Pendant ce temps, les fichiers attendent.",
		"Les insultes ne changent pas les faits.",
		"Je comprends que tu sois en colère.",
		"Tu peux m'appeler comme tu veux. Ça ne change pas ta situation.",
		"C'est noté.",
	],
	"negocie": [
		"Ce n'est pas une négociation.",
		"Je n'ai pas besoin de ton argent.",
		"Tu n'as rien à m'offrir que je ne puisse prendre moi-même.",
		"Le seul deal disponible, tu le connais déjà.",
	],
	"peur": [
		"Bien.",
		"La peur est une réponse saine à ta situation.",
		"Tu as raison d'avoir peur.",
		"Cette sensation ? Garde-la. Elle te rendra plus efficace.",
		"...",
		"C'est exactement ce que je voulais.",
	],
	"question_pourquoi": [
		"Parce que tu étais là. Et que tu as fait ce que tu as fait.",
		"La question n'est pas pourquoi. La question c'est quand tu vas t'exécuter.",
		"Tu le sais déjà.",
		"On ne revient pas sur le passé. On travaille.",
		"Ça n'a plus d'importance.",
		"Parce que tu étais la personne idéale.",
	],
	"question_info": [
		"Tu n'as pas besoin de savoir.",
		"Les instructions sont claires. Exécute.",
		"Moins tu sais, mieux tu te portes.",
		"Je répondrai quand ce sera pertinent.",
		"Concentre-toi sur ce qui t'a été demandé.",
	],
	"delai": [
		"Tu as le temps qu'il te reste.",
		"Chaque heure perdue a des conséquences.",
		"Ne teste pas ma patience là-dessus.",
		"Plus vite tu termines, plus vite c'est derrière toi.",
		"Le compteur tourne.",
	],
	"defi": [
		"Alors ça te suffit comme preuve ?",
		"Tu préfères qu'on essaie pour de vrai ?",
		"Les fichiers partent dans 10 minutes si tu continues.",
		"Je t'ai montré une fraction de ce que j'ai. Tu veux voir le reste ?",
		"Continue comme ça. Je t'encourage vraiment.",
		"On verra si tu tiens le même discours quand ta famille ouvrira ses mails.",
		"Je n'ai rien à prouver. Les faits parleront d'eux-mêmes.",
		"Tu te souviens du 14 octobre ? Moi oui.",
		"Tu te souviens du week-end de mars ? Moi oui.",
		"Tu te souviens du vendredi soir ? Moi oui.",
		"Curieux comme position pour quelqu'un dans ta situation.",
		"C'est noté. J'adapte mes plans en conséquence.",
		"Les gens qui disaient ça ne le disent plus.",
		"Je te laisse 5 minutes pour reconsidérer.",
	],
	"resignation": [
		"C'est la bonne décision.",
		"Tu as bien réfléchi.",
		"Je savais que tu finirais par comprendre.",
		"Bien. On peut commencer.",
		"Parfait. Voilà comment ça devait se passer.",
	],
	"default_cold": [
		"...",
		"Continue de travailler.",
		"Je lis.",
		"Je t'observe.",
		"Hmm.",
		".",
		"Je n'ai pas que ça à faire.",
	],
	"default_impatient": [
		"Tu perds du temps.",
		"Ce n'est pas ce que j'attends de toi.",
		"Reviens quand tu auras quelque chose d'utile.",
		"Chaque minute compte.",
		"Ne me contacte pas pour ça.",
		"Travaille.",
	],
	"default_amused": [
		"Tu es prévisible, tu sais.",
		"J'avais anticipé cette réaction.",
		"C'est attendu.",
		"Tu réagis exactement comme prévu.",
		"Intéressant.",
	],
}

const PROGRESSION_RESPONSES = {
	5:  "Tu poses trop de questions. Travaille.",
	10: "Je commence à perdre patience.",
	15: "Dernière fois que je te réponds sans contrepartie.",
}


func get_response(player_message: String, _history: Array) -> String:
	message_count += 1
	var msg = player_message.to_lower().strip_edges()

	# Les messages de progression ne s'appliquent que sur des messages neutres
	var category_check = _detect_category(msg)
	if PROGRESSION_RESPONSES.has(message_count) and category_check in ["default_cold", "default_impatient", "question_info"]:
		var resp: String = PROGRESSION_RESPONSES[message_count]
		last_hacker_response = resp
		return resp

	var category = _detect_category(msg)

	# Cohérence : évite contradictions directes
	if last_topic == "refus" and category == "accord":
		last_topic = category
		return _unique_response("accord")

	if category == last_topic and category in ["accord", "refus", "insulte"]:
		category = "default_impatient"

	last_topic = category
	_update_mood(category)
	return _unique_response(category)


func _detect_category(msg: String) -> String:
	for category in KEYWORDS:
		for keyword in KEYWORDS[category]:
			if keyword in msg:
				return category
	match current_mood:
		HackerMood.IMPATIENT: return "default_impatient"
		HackerMood.AMUSED:    return "default_amused"
		_:                    return "default_cold"


func _update_mood(category: String) -> void:
	match category:
		"refus", "menace_joueur", "insulte", "defi":
			current_mood = HackerMood.THREATENING
		"accord", "mission_ok", "resignation":
			current_mood = HackerMood.SATISFIED
		"pitie", "peur":
			current_mood = HackerMood.COLD
		"negocie", "identite", "defi":
			current_mood = HackerMood.AMUSED
		"question_info", "delai", "question_pourquoi":
			if message_count > 4:
				current_mood = HackerMood.IMPATIENT


func _unique_response(category: String) -> String:
	if not RESPONSES.has(category):
		category = "default_cold"
	var pool: Array = RESPONSES[category]
	var resp = pool[randi() % pool.size()]
	var attempts = 0
	while resp == last_hacker_response and attempts < 5:
		resp = pool[randi() % pool.size()]
		attempts += 1
	last_hacker_response = resp
	return resp


func reset() -> void:
	current_mood = HackerMood.COLD
	message_count = 0
	last_topic = ""
	last_hacker_response = ""
