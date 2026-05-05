# browser_pages.gd
# Contenu statique du navigateur darknet EAX37
# Toutes les méthodes sont statiques — aucun état, juste du BBCode.
class_name BrowserPages

const HOME := "dread4imkgxvk46m.onion"

const C_TEXT     = "#b0b0cc"
const C_TEXT_DIM = "#484866"
const C_BRIGHT   = "#e0e0f0"
const C_LINK     = "#a855f7"
const C_WARN     = "#ef4444"
const C_GREEN    = "#22c55e"
const C_ORANGE   = "#f97316"
const C_BLUE     = "#3b82f6"
const C_PURPLE   = "#7c3aed"
const C_BORDER   = "#1c1c2e"


# ═══════════════════════════════════════════════════
# ROUTEUR
# ═══════════════════════════════════════════════════
static func get_page(url: String) -> String:
	match url:
		HOME, HOME + "/":
			return page_home()
		HOME + "/r/jobs":
			return page_board_jobs()
		HOME + "/r/tools":
			return page_board_tools()
		HOME + "/r/intel":
			return page_board_intel()
		HOME + "/r/comms":
			return page_board_comms()
		HOME + "/t/jobs/1":
			return page_thread_jobs_1()
		HOME + "/t/jobs/2":
			return page_thread_jobs_2()
		HOME + "/t/jobs/3":
			return page_thread_jobs_3()
		HOME + "/t/tools/1":
			return page_thread_tools_1()
		HOME + "/t/tools/2":
			return page_thread_tools_2()
		HOME + "/t/tools/3":
			return page_thread_tools_3()
		HOME + "/t/intel/1":
			return page_thread_intel_1()
		HOME + "/t/intel/2":
			return page_thread_intel_2()
		HOME + "/t/intel/3":
			return page_thread_intel_3()
		HOME + "/t/comms/1":
			return page_thread_comms_1()
		HOME + "/t/comms/2":
			return page_thread_comms_2()
		HOME + "/u/unknown":
			return page_user_unknown()
		HOME + "/u/ghost_proc":
			return page_user_ghost()
		HOME + "/u/d4rk_n3t":
			return page_user_d4rk()
		HOME + "/u/r00t_k1t":
			return page_user_r00t()
		HOME + "/u/proxy_null":
			return page_user_proxy_null()
		HOME + "/u/anon_8821":
			return page_user_anon()
		HOME + "/u/v0id_run":
			return page_user_v0id()
		HOME + "/u/z3r0_tr4ce":
			return page_user_z3r0()
		HOME + "/login":
			return page_login()
		_:
			return page_404(url)


# ═══════════════════════════════════════════════════
# HELPERS BBCODE
# IMPORTANT : [url] doit toujours être la balise la plus externe
# pour que meta_hover_started se déclenche correctement dans Godot 4.
# ═══════════════════════════════════════════════════
static func _header(subtitle: String = "") -> String:
	var sub := ("  " + subtitle) if not subtitle.is_empty() else ""
	return (
		"[color=#3b0f6e]▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓[/color]\n"
		+ "[b][color=#e0e0f0]  D · R · E · A · D[/color][/b]"
		+ "   [color=#484866]forum anonyme · réseau oignon · v4.2[/color]\n"
		+ "[color=#3b0f6e]▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓[/color]\n"
		+ "[color=#484866]" + sub + "[/color]\n\n"
	)


static func _nav() -> String:
	return (
		"  [url=" + HOME + "][color=#a855f7]⌂ Accueil[/color][/url]"
		+ "   [url=" + HOME + "/r/jobs][color=#f97316]Jobs[/color][/url]"
		+ "   [url=" + HOME + "/r/tools][color=#22c55e]Outils[/color][/url]"
		+ "   [url=" + HOME + "/r/intel][color=#3b82f6]Intel[/color][/url]"
		+ "   [url=" + HOME + "/r/comms][color=#7c3aed]Comms[/color][/url]"
		+ "   [url=" + HOME + "/login][color=#484866][ connexion ][/color][/url]\n"
		+ "[color=#1c1c2e]──────────────────────────────────────────────[/color]\n\n"
	)


static func _sep() -> String:
	return "[color=#1c1c2e]──────────────────────────────────────────────[/color]\n"


## Post avec username cliquable si user_id est fourni.
## [url] est TOUJOURS la balise la plus externe pour garantir le hover.
static func _post(username: String, color: String, time: String, body: String, user_id: String = "") -> String:
	var name_part: String
	if user_id.is_empty():
		name_part = "[b][color=" + color + "]" + username + "[/color][/b]"
	else:
		name_part = "[url=" + HOME + "/u/" + user_id + "][b][color=" + color + "]" + username + "[/color][/b][/url]"
	return (
		name_part
		+ "  [color=#484866]" + time + "[/color]\n"
		+ "[color=#b0b0cc]" + body + "[/color]\n\n"
	)


# ═══════════════════════════════════════════════════
# PAGE ACCUEIL
# ═══════════════════════════════════════════════════
static func page_home() -> String:
	return (
		_header()
		+ _nav()
		+ "[b][color=#e0e0f0]  TABLEAUX[/color][/b]\n\n"

		+ "  [url=" + HOME + "/r/jobs][b][color=#f97316][ JOBS ][/color][/b][/url]"
		+ "  [color=#b0b0cc]Contrats & missions rémunérées[/color]\n"
		+ "  [color=#484866]    23 fils · dernier post il y a 12 min[/color]\n\n"

		+ "  [url=" + HOME + "/r/tools][b][color=#22c55e][ OUTILS ][/color][/b][/url]"
		+ "  [color=#b0b0cc]Logiciels, scripts, exploits[/color]\n"
		+ "  [color=#484866]    47 fils · dernier post il y a 3h[/color]\n\n"

		+ "  [url=" + HOME + "/r/intel][b][color=#3b82f6][ INTEL ][/color][/b][/url]"
		+ "  [color=#b0b0cc]Cibles, réseaux, cartographies OSINT[/color]\n"
		+ "  [color=#484866]    31 fils · dernier post il y a 45 min[/color]\n\n"

		+ "  [url=" + HOME + "/r/comms][b][color=#7c3aed][ COMMS ][/color][/b][/url]"
		+ "  [color=#b0b0cc]Communication sécurisée, clés PGP[/color]\n"
		+ "  [color=#484866]    12 fils · dernier post il y a 2h[/color]\n\n"

		+ _sep()
		+ "[b][color=#e0e0f0]  FILS RÉCENTS[/color][/b]\n\n"

		+ "  [url=" + HOME + "/t/jobs/1][color=#f97316]▶[/color]"
		+ " [color=#b0b0cc][CONTRACT] Accès réseau corp. — paiement immédiat[/color][/url]\n"
		+ "  [color=#484866]    r/jobs · UNKNOWN_▓▓▓ · il y a 18 min · 4 rép.[/color]\n\n"

		+ "  [url=" + HOME + "/t/intel/1][color=#3b82f6]▶[/color]"
		+ " [color=#b0b0cc]EAX37 Corp — cartographie réseau 2026[/color][/url]\n"
		+ "  [color=#484866]    r/intel · d4rk_n3t · il y a 1h · 11 rép.[/color]\n\n"

		+ "  [url=" + HOME + "/t/tools/1][color=#22c55e]▶[/color]"
		+ " [color=#b0b0cc]ssh-bruteX v3.1 — wordlist 2026 mise à jour[/color][/url]\n"
		+ "  [color=#484866]    r/tools · ghost_proc · il y a 3h · 7 rép.[/color]\n\n"

		+ "  [url=" + HOME + "/t/jobs/2][color=#f97316]▶[/color]"
		+ " [color=#b0b0cc]ISO opérateur qualifié — exfiltration fichiers[/color][/url]\n"
		+ "  [color=#484866]    r/jobs · proxy_null · il y a 5h · 2 rép.[/color]\n\n"

		+ "  [url=" + HOME + "/t/intel/2][color=#3b82f6]▶[/color]"
		+ " [color=#b0b0cc]Dump credentials — serveur log compromis[/color][/url]\n"
		+ "  [color=#484866]    r/intel · anon_8821 · il y a 6h · 3 rép.[/color]\n\n"

		+ "  [url=" + HOME + "/t/intel/3][color=#3b82f6]▶[/color]"
		+ " [color=#b0b0cc]/etc/passwd leak — comptes actifs EAX37[/color][/url]\n"
		+ "  [color=#484866]    r/intel · v0id_run · il y a 8h · 5 rép.[/color]\n\n"

		+ _sep()
		+ "[color=#484866]  Connecté via TOR · Nœud de sortie : NL-AMS-7 · Latence : 340ms · Utilisateurs actifs : 47[/color]\n"
	)


# ═══════════════════════════════════════════════════
# BOARDS
# ═══════════════════════════════════════════════════
static func page_board_jobs() -> String:
	return (
		_header("r/jobs — Contrats & Missions")
		+ _nav()
		+ "[b][color=#f97316]  r/JOBS[/color][/b]   [color=#484866]Contrats, missions, paiements BTC/XMR[/color]\n"
		+ "[color=#ef4444]  ⚠ Utilisez toujours un intermédiaire. Aucun remboursement.[/color]\n\n"
		+ _sep()

		+ "  [url=" + HOME + "/t/jobs/1][b][color=#f97316][CONTRACT][/color]"
		+ " [color=#e0e0f0]Accès réseau corp. — paiement immédiat[/color][/b][/url]\n"
		+ "  [color=#484866]    UNKNOWN_▓▓▓ · il y a 18 min · [color=#22c55e]4 rép.[/color][/color]\n\n"

		+ "  [url=" + HOME + "/t/jobs/2][b][color=#f97316][ISO][/color]"
		+ " [color=#e0e0f0]Opérateur qualifié — exfiltration fichiers[/color][/b][/url]\n"
		+ "  [color=#484866]    proxy_null · il y a 5h · 2 rép.[/color]\n\n"

		+ "  [url=" + HOME + "/t/jobs/3][b][color=#484866][FERMÉ][/color]"
		+ " [color=#484866]Besoin accès SSH — résolu[/color][/b][/url]\n"
		+ "  [color=#484866]    v0id_run · il y a 2j · 9 rép.[/color]\n\n"

		+ _sep()
		+ "[color=#484866]  23 fils · Page 1/3[/color]\n"
	)


static func page_board_tools() -> String:
	return (
		_header("r/tools — Outils & Exploits")
		+ _nav()
		+ "[b][color=#22c55e]  r/TOOLS[/color][/b]   [color=#484866]Scripts, frameworks, exploits partagés[/color]\n\n"
		+ _sep()

		+ "  [url=" + HOME + "/t/tools/1][b][color=#22c55e][RELEASE][/color]"
		+ " [color=#e0e0f0]ssh-bruteX v3.1 — wordlist 2026 incluse[/color][/b][/url]\n"
		+ "  [color=#484866]    ghost_proc · il y a 3h · 7 rép.[/color]\n\n"

		+ "  [url=" + HOME + "/t/tools/2][b][color=#22c55e][SCRIPT][/color]"
		+ " [color=#e0e0f0]nmap-auto — scan silencieux + rapport JSON[/color][/b][/url]\n"
		+ "  [color=#484866]    r00t_k1t · il y a 1j · 4 rép.[/color]\n\n"

		+ "  [url=" + HOME + "/t/tools/3][b][color=#22c55e][TOOL][/color]"
		+ " [color=#e0e0f0]LogWiper 2.0 — effacement traces système[/color][/b][/url]\n"
		+ "  [color=#484866]    z3r0_tr4ce · il y a 3j · 12 rép.[/color]\n\n"

		+ _sep()
		+ "[color=#484866]  47 fils · Page 1/5[/color]\n"
	)


static func page_board_intel() -> String:
	return (
		_header("r/intel — Intelligence & Cibles")
		+ _nav()
		+ "[b][color=#3b82f6]  r/INTEL[/color][/b]   [color=#484866]OSINT, cartographies réseau, dumps[/color]\n"
		+ "[color=#ef4444]  ⚠ Ne postez que ce que vous avez obtenu vous-même.[/color]\n\n"
		+ _sep()

		+ "  [url=" + HOME + "/t/intel/1][b][color=#3b82f6][MAP][/color]"
		+ " [color=#e0e0f0]EAX37 Corp — cartographie réseau 2026[/color][/b][/url]\n"
		+ "  [color=#484866]    d4rk_n3t · il y a 1h · 11 rép.[/color]\n\n"

		+ "  [url=" + HOME + "/t/intel/2][b][color=#3b82f6][DUMP][/color]"
		+ " [color=#e0e0f0]Credentials serveur log compromis — 140 entrées[/color][/b][/url]\n"
		+ "  [color=#484866]    anon_8821 · il y a 6h · 3 rép.[/color]\n\n"

		+ "  [url=" + HOME + "/t/intel/3][b][color=#3b82f6][LEAK][/color]"
		+ " [color=#e0e0f0]/etc/passwd — comptes actifs EAX37[/color][/b][/url]\n"
		+ "  [color=#484866]    v0id_run · il y a 8h · 5 rép.[/color]\n\n"

		+ _sep()
		+ "[color=#484866]  31 fils · Page 1/4[/color]\n"
	)


static func page_board_comms() -> String:
	return (
		_header("r/comms — Communication Sécurisée")
		+ _nav()
		+ "[b][color=#7c3aed]  r/COMMS[/color][/b]   [color=#484866]PGP, canaux sécurisés, dead drops[/color]\n\n"
		+ _sep()

		+ "  [url=" + HOME + "/t/comms/1][b][color=#7c3aed][PGP][/color]"
		+ " [color=#e0e0f0]Clé publique — UNKNOWN_▓▓▓[/color][/b][/url]\n"
		+ "  [color=#484866]    UNKNOWN_▓▓▓ · il y a 2j · 0 rép.[/color]\n\n"

		+ "  [url=" + HOME + "/t/comms/2][b][color=#7c3aed][OPSEC][/color]"
		+ " [color=#e0e0f0]Protocole communication — règles du forum[/color][/b][/url]\n"
		+ "  [color=#484866]    admin · épinglé · 34 rép.[/color]\n\n"

		+ _sep()
		+ "[color=#484866]  12 fils · Page 1/2[/color]\n"
	)


# ═══════════════════════════════════════════════════
# THREADS JOBS
# ═══════════════════════════════════════════════════
static func page_thread_jobs_1() -> String:
	return (
		_header("r/jobs › [CONTRACT] Accès réseau corp.")
		+ _nav()
		+ "[url=" + HOME + "/r/jobs][color=#a855f7]← retour r/jobs[/color][/url]\n\n"
		+ "[b][color=#f97316][CONTRACT][/color] [color=#e0e0f0]Accès réseau corp. — paiement immédiat[/color][/b]\n"
		# [url] outermost — pas de [color] extérieur autour de [url]
		+ "[url=" + HOME + "/u/unknown][color=#ef4444]UNKNOWN_▓▓▓[/color][/url]"
		+ "[color=#484866] · il y a 18 min · r/jobs[/color]\n"
		+ _sep()
		+ "[color=#b0b0cc]J'ai besoin d'un accès à un réseau interne d'entreprise.\n"
		+ "Cible : [b]EAX37 Corp[/b]\n"
		+ "Objectif : récupérer un fichier spécifique depuis leur serveur de logs.\n\n"
		+ "Détails transmis en privé à l'opérateur sélectionné.\n"
		+ "Paiement : [color=#f97316]0.3 BTC[/color] — livraison confirmée, virement immédiat.\n\n"
		+ "Profil requis :\n"
		+ "  — Maîtrise des outils standard (nmap, ssh, cat...)\n"
		+ "  — Discrétion absolue\n"
		+ "  — Disponibilité immédiate[/color]\n\n"
		+ "[color=#484866]Répondez ici ou via l'application Cipher.[/color]\n\n"
		+ _sep()
		+ _post("r00t_k1t",   "#22c55e", "il y a 15 min", "Je suis dispo. Message envoyé.", "r00t_k1t")
		+ _post("ghost_proc", "#22c55e", "il y a 12 min",
			"EAX37 ? Leur réseau est pas simple.\nT'as déjà un point d'entrée ?", "ghost_proc")
		+ _post("UNKNOWN_▓▓▓", "#ef4444", "il y a 10 min",
			"Opérateur trouvé. [b]Fil fermé aux nouvelles candidatures.[/b]", "unknown")
		+ _post("proxy_null", "#22c55e", "il y a 3 min",
			"Trop tard alors. Bonne chance à l'heureux élu.", "proxy_null")
		+ _sep()
	)


static func page_thread_jobs_2() -> String:
	return (
		_header("r/jobs › ISO Opérateur qualifié")
		+ _nav()
		+ "[url=" + HOME + "/r/jobs][color=#a855f7]← retour r/jobs[/color][/url]\n\n"
		+ "[b][color=#f97316][ISO][/color] [color=#e0e0f0]Opérateur qualifié — exfiltration fichiers[/color][/b]\n"
		+ "[url=" + HOME + "/u/proxy_null][color=#22c55e]proxy_null[/color][/url]"
		+ "[color=#484866] · il y a 5h · r/jobs[/color]\n"
		+ _sep()
		+ "[color=#b0b0cc]Besoin d'un opérateur pour récupérer des documents sur un serveur distant.\n"
		+ "Serveur : Linux, accès SSH potentiellement disponible.\n"
		+ "Fichiers cibles : répertoire [color=#22c55e]/var/log/[/color]\n\n"
		+ "Paiement : [color=#f97316]0.8 BTC[/color] négociable selon profil.[/color]\n\n"
		+ _sep()
		+ _post("d4rk_n3t",  "#22c55e", "il y a 4h", "Intéressant. Quel OS côté serveur ?", "d4rk_n3t")
		+ _post("proxy_null", "#22c55e", "il y a 3h",
			"Ubuntu 22.04 d'après les headers. Pas de 2FA connu.", "proxy_null")
		+ _sep()
	)


static func page_thread_jobs_3() -> String:
	return (
		_header("r/jobs › [FERMÉ] Accès SSH")
		+ _nav()
		+ "[url=" + HOME + "/r/jobs][color=#a855f7]← retour r/jobs[/color][/url]\n\n"
		+ "[b][color=#484866][FERMÉ][/color] [color=#484866]Besoin accès SSH — résolu[/color][/b]\n"
		+ "[url=" + HOME + "/u/v0id_run][color=#b0b0cc]v0id_run[/color][/url]"
		+ "[color=#484866] · il y a 2 jours · r/jobs[/color]\n"
		+ _sep()
		+ "[color=#484866]Mission complétée. Merci à l'opérateur. Paiement envoyé.[/color]\n\n"
		+ _sep()
	)


# ═══════════════════════════════════════════════════
# THREADS TOOLS
# ═══════════════════════════════════════════════════
static func page_thread_tools_1() -> String:
	return (
		_header("r/tools › ssh-bruteX v3.1")
		+ _nav()
		+ "[url=" + HOME + "/r/tools][color=#a855f7]← retour r/tools[/color][/url]\n\n"
		+ "[b][color=#22c55e][RELEASE][/color] [color=#e0e0f0]ssh-bruteX v3.1 — wordlist 2026 incluse[/color][/b]\n"
		+ "[url=" + HOME + "/u/ghost_proc][color=#22c55e]ghost_proc[/color][/url]"
		+ "[color=#484866] · il y a 3h · r/tools[/color]\n"
		+ _sep()
		+ "[color=#b0b0cc]Mise à jour majeure.\n\n"
		+ "[b]Nouveautés v3.1 :[/b]\n"
		+ "  — Wordlist rockyou2026 intégrée (2.1M entrées)\n"
		+ "  — Mode silencieux (contourne fail2ban si délai ≥ 3s)\n"
		+ "  — Support IPv6\n"
		+ "  — Export rapport JSON\n\n"
		+ "[b]Usage :[/b]\n"
		+ "[color=#22c55e]  ./ssh-brutex -h <cible> -u <user> -w wordlist.txt --delay 4[/color]\n\n"
		+ "SHA256 : [color=#484866]a3f1b9c2d4e5f6a7b8c9d0e1f2a3b4c5[/color][/color]\n\n"
		+ _sep()
		+ _post("r00t_k1t",   "#22c55e", "il y a 2h",
			"Testé sur une cible privée. Délai 4s, aucune alerte. Efficace.", "r00t_k1t")
		+ _post("d4rk_n3t",   "#22c55e", "il y a 1h30",
			"La wordlist rockyou2026 est vraiment complète. Fortement recommandé.", "d4rk_n3t")
		+ _post("z3r0_tr4ce", "#22c55e", "il y a 1h",
			"Attention : certains SSH modernes bloquent après 3 tentatives même avec délai.\n"
			+ "Pensez à combiner avec un proxy rotatif.", "z3r0_tr4ce")
		+ _post("ghost_proc", "#22c55e", "il y a 45 min",
			"Bonne remarque. Prochaine version aura le support SOCKS5.", "ghost_proc")
		+ _sep()
	)


static func page_thread_tools_2() -> String:
	return (
		_header("r/tools › nmap-auto")
		+ _nav()
		+ "[url=" + HOME + "/r/tools][color=#a855f7]← retour r/tools[/color][/url]\n\n"
		+ "[b][color=#22c55e][SCRIPT][/color] [color=#e0e0f0]nmap-auto — scan silencieux + rapport JSON[/color][/b]\n"
		+ "[url=" + HOME + "/u/r00t_k1t][color=#22c55e]r00t_k1t[/color][/url]"
		+ "[color=#484866] · il y a 1j · r/tools[/color]\n"
		+ _sep()
		+ "[color=#b0b0cc]Wrapper bash pour nmap, génère un rapport JSON propre.\n\n"
		+ "[b]Usage :[/b]\n"
		+ "[color=#22c55e]  nmap-auto <ip> [--full] [--stealth] [--out rapport.json][/color]\n\n"
		+ "[b]Mode stealth :[/b] timing T1, fragmentation paquets, decoys aléatoires.\n"
		+ "Idéal pour éviter les IDS sur des cibles surveillées.[/color]\n\n"
		+ _sep()
		+ _post("anon_8821", "#22c55e", "il y a 20h",
			"Fonctionne bien. J'ai scanné EAX37 avec --stealth, rien dans leurs logs.", "anon_8821")
		+ _post("z3r0_tr4ce", "#22c55e", "il y a 18h",
			"Pratique. Je l'ai branché sur un cron toutes les 6h pour du monitoring passif.", "z3r0_tr4ce")
		+ _post("r00t_k1t", "#22c55e", "il y a 10h",
			"Nouvelle option --diff dans la prochaine version : compare deux scans et sort les changements.", "r00t_k1t")
		+ _sep()
	)


static func page_thread_tools_3() -> String:
	return (
		_header("r/tools › LogWiper 2.0")
		+ _nav()
		+ "[url=" + HOME + "/r/tools][color=#a855f7]← retour r/tools[/color][/url]\n\n"
		+ "[b][color=#22c55e][TOOL][/color] [color=#e0e0f0]LogWiper 2.0 — effacement traces système[/color][/b]\n"
		+ "[url=" + HOME + "/u/z3r0_tr4ce][color=#22c55e]z3r0_tr4ce[/color][/url]"
		+ "[color=#484866] · il y a 3j · r/tools[/color]\n"
		+ _sep()
		+ "[color=#b0b0cc]Efface proprement :\n"
		+ "  — /var/log/auth.log\n"
		+ "  — /var/log/syslog\n"
		+ "  — ~/.bash_history\n"
		+ "  — lastlog / wtmp / btmp\n\n"
		+ "[color=#ef4444]Requiert root.[/color]\n\n"
		+ "[color=#22c55e]  sudo ./logwiper --all --secure --zero-fill[/color]\n\n"
		+ "Option [color=#22c55e]--zero-fill[/color] : écrase avec des zéros avant suppression (forensics safe).[/color]\n\n"
		+ _sep()
		+ _post("ghost_proc", "#22c55e", "il y a 2j",
			"Très utile après une op. J'utilise ça systématiquement.", "ghost_proc")
		+ _post("r00t_k1t", "#22c55e", "il y a 2j",
			"Est-ce que ça gère aussi les logs journald ? systemd les stocke différemment.", "r00t_k1t")
		+ _post("z3r0_tr4ce", "#22c55e", "il y a 1j",
			"Bonne remarque. Ajouté dans la v2.1 en cours :\n"
			+ "[color=#22c55e]journalctl --rotate && journalctl --vacuum-time=1s[/color]\n"
			+ "Disponible la semaine prochaine.", "z3r0_tr4ce")
		+ _sep()
	)


# ═══════════════════════════════════════════════════
# THREADS INTEL
# ═══════════════════════════════════════════════════
static func page_thread_intel_1() -> String:
	return (
		_header("r/intel › EAX37 Corp — réseau 2026")
		+ _nav()
		+ "[url=" + HOME + "/r/intel][color=#a855f7]← retour r/intel[/color][/url]\n\n"
		+ "[b][color=#3b82f6][MAP][/color] [color=#e0e0f0]EAX37 Corp — cartographie réseau 2026[/color][/b]\n"
		+ "[url=" + HOME + "/u/d4rk_n3t][color=#22c55e]d4rk_n3t[/color][/url]"
		+ "[color=#484866] · il y a 1h · r/intel[/color]\n"
		+ _sep()
		+ "[color=#b0b0cc]Résultats OSINT complets sur EAX37 Corp.\n\n"
		+ "[b]Infrastructure identifiée :[/b]\n\n"
		+ "[color=#22c55e]  10.0.0.1  [/color]  [color=#484866]fw-01     — Routeur/Firewall principal[/color]\n"
		+ "[color=#22c55e]  10.0.0.10 [/color]  [color=#484866]web-01    — Apache 2.4 (ports 80/443)[/color]\n"
		+ "[color=#ef4444]  10.0.0.20 [/color]  [color=#484866]log-01    — Serveur de logs (SSH port 22 ouvert)[/color]\n"
		+ "[color=#22c55e]  10.0.0.30 [/color]  [color=#484866]db-01     — MySQL (interne seulement)[/color]\n"
		+ "[color=#22c55e]  10.0.0.100[/color]  [color=#484866]admin     — Poste admin (RDP, VPN requis)[/color]\n\n"
		+ "[b]Points d'intérêt :[/b]\n"
		+ "  — [color=#ef4444]log-01[/color] : pas de fail2ban détecté lors du dernier scan\n"
		+ "  — Potentiels credentials par défaut encore actifs\n"
		+ "  — /etc/passwd lisible sans auth (mauvaise config sudo)\n"
		+ "  — Fichiers cibles dans [color=#22c55e]/var/log/secure[/color] et [color=#22c55e]/var/log/auth.log[/color][/color]\n\n"
		+ _sep()
		+ _post("ghost_proc", "#22c55e", "il y a 45 min",
			"Confirmé pour log-01. Port 22 répond bien, banner SSH visible.", "ghost_proc")
		+ _post("anon_8821", "#22c55e", "il y a 30 min",
			"Le fichier cible est dans /var/log/secure d'après ma source interne.", "anon_8821")
		+ _post("r00t_k1t", "#22c55e", "il y a 20 min",
			"Scan stealth effectué. Aucune réponse IDS. Timing T2 suffisant.", "r00t_k1t")
		+ _post("proxy_null", "#22c55e", "il y a 10 min",
			"Quelqu'un sait qui a le contrat sur ce réseau ?\nJ'ai vu passer un post dans r/jobs...", "proxy_null")
		+ _sep()
	)


static func page_thread_intel_2() -> String:
	return (
		_header("r/intel › Dump credentials")
		+ _nav()
		+ "[url=" + HOME + "/r/intel][color=#a855f7]← retour r/intel[/color][/url]\n\n"
		+ "[b][color=#3b82f6][DUMP][/color] [color=#e0e0f0]Credentials serveur log compromis — 140 entrées[/color][/b]\n"
		+ "[url=" + HOME + "/u/anon_8821][color=#b0b0cc]anon_8821[/color][/url]"
		+ "[color=#484866] · il y a 6h · r/intel[/color]\n"
		+ _sep()
		+ "[color=#b0b0cc]Dump partiel d'un /etc/shadow récupéré sur log-01.\n"
		+ "Format : user:hash\n\n"
		+ "[color=#22c55e]root:$6$rounds=5000$▓▓▓▓▓▓▓▓$▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓[/color]\n"
		+ "[color=#22c55e]hacker:$6$rounds=5000$▓▓▓▓▓▓▓▓$▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓[/color]\n"
		+ "[color=#22c55e]deploy:$6$rounds=5000$▓▓▓▓▓▓▓▓$▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓[/color]\n"
		+ "[color=#22c55e]sysadmin:$6$rounds=5000$▓▓▓▓▓▓▓▓$▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓[/color]\n\n"
		+ "[color=#ef4444]Hashes non crackés. Si quelqu'un a du temps GPU...[/color][/color]\n\n"
		+ _sep()
		+ _post("ghost_proc", "#22c55e", "il y a 5h",
			"Le compte deploy a souvent des mots de passe faibles. À tenter en priorité.", "ghost_proc")
		+ _post("r00t_k1t", "#22c55e", "il y a 4h",
			"En cours de crack avec hashcat. Je reviens si j'ai quelque chose.", "r00t_k1t")
		+ _post("z3r0_tr4ce", "#22c55e", "il y a 2h",
			"Pas besoin de cracker si les credentials par défaut sont actifs.\n"
			+ "Essayez : admin:admin, deploy:deploy, hacker:hacker...", "z3r0_tr4ce")
		+ _sep()
	)


static func page_thread_intel_3() -> String:
	return (
		_header("r/intel › /etc/passwd leak — EAX37")
		+ _nav()
		+ "[url=" + HOME + "/r/intel][color=#a855f7]← retour r/intel[/color][/url]\n\n"
		+ "[b][color=#3b82f6][LEAK][/color] [color=#e0e0f0]/etc/passwd — comptes actifs EAX37[/color][/b]\n"
		+ "[url=" + HOME + "/u/v0id_run][color=#b0b0cc]v0id_run[/color][/url]"
		+ "[color=#484866] · il y a 8h · r/intel[/color]\n"
		+ _sep()
		+ "[color=#b0b0cc]Contenu /etc/passwd du serveur log-01.\n\n"
		+ "[color=#22c55e]root:x:0:0:root:/root:/bin/bash[/color]\n"
		+ "[color=#22c55e]daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin[/color]\n"
		+ "[color=#22c55e]hacker:x:1000:1000::/home/hacker:/bin/bash[/color]\n"
		+ "[color=#22c55e]deploy:x:1001:1001::/home/deploy:/bin/bash[/color]\n"
		+ "[color=#22c55e]sysadmin:x:1002:1002::/home/sysadmin:/bin/bash[/color]\n"
		+ "[color=#22c55e]backup:x:1003:1003::/var/backups:/bin/sh[/color]\n\n"
		+ "Comptes avec shell actif : root, hacker, deploy, sysadmin, backup[/color]\n\n"
		+ _sep()
		+ _post("anon_8821", "#22c55e", "il y a 7h",
			"Le compte hacker est intéressant. Probablement un compte de test laissé actif.", "anon_8821")
		+ _post("ghost_proc", "#22c55e", "il y a 6h",
			"hacker:hacker est un classique. Quelqu'un a tenté ?", "ghost_proc")
		+ _post("v0id_run", "#22c55e", "il y a 5h",
			"Essayé hacker:hacker et hacker:1234. Rien.\n"
			+ "Peut-être dans le dump shadow si quelqu'un crack les hashes.", "v0id_run")
		+ _post("proxy_null", "#22c55e", "il y a 3h",
			"On sait que quelqu'un a déjà le contrat sur cette cible.\n"
			+ "S'il réussit, il partagera peut-être les accès.", "proxy_null")
		+ _sep()
	)


# ═══════════════════════════════════════════════════
# THREADS COMMS
# ═══════════════════════════════════════════════════
static func page_thread_comms_1() -> String:
	return (
		_header("r/comms › Clé PGP — UNKNOWN_▓▓▓")
		+ _nav()
		+ "[url=" + HOME + "/r/comms][color=#a855f7]← retour r/comms[/color][/url]\n\n"
		+ "[b][color=#7c3aed][PGP][/color] [color=#e0e0f0]Clé publique — UNKNOWN_▓▓▓[/color][/b]\n"
		+ "[url=" + HOME + "/u/unknown][color=#ef4444]UNKNOWN_▓▓▓[/color][/url]"
		+ "[color=#484866] · il y a 2j · r/comms[/color]\n"
		+ _sep()
		+ "[color=#b0b0cc]Clé publique PGP pour communications chiffrées.\n"
		+ "Utilisez l'application Cipher pour les échanges directs et sécurisés.\n\n"
		+ "[color=#484866]-----BEGIN PGP PUBLIC KEY BLOCK-----\n"
		+ "Version: GnuPG v2.2.▓▓\n\n"
		+ "mQINBF▓▓▓▓▓▓BBAD▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓\n"
		+ "▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓\n"
		+ "▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓\n"
		+ "=▓▓▓▓\n"
		+ "-----END PGP PUBLIC KEY BLOCK-----[/color][/color]\n\n"
		+ _sep()
	)


static func page_thread_comms_2() -> String:
	return (
		_header("r/comms › Protocole communication")
		+ _nav()
		+ "[url=" + HOME + "/r/comms][color=#a855f7]← retour r/comms[/color][/url]\n\n"
		+ "[b][color=#7c3aed][OPSEC][/color] [color=#e0e0f0]Protocole communication — règles du forum[/color][/b]\n"
		+ "[color=#484866]admin · épinglé · r/comms[/color]\n"
		+ _sep()
		+ "[b][color=#e0e0f0]Règles de communication sur ce forum :[/color][/b]\n\n"
		+ "[color=#b0b0cc]1. Toujours passer par TOR. Jamais de clearnet.\n"
		+ "2. Ne jamais donner d'informations personnelles identifiables.\n"
		+ "3. Utilisez PGP pour tout échange de données sensibles.\n"
		+ "4. Les coordinations de missions se font via [b]Cipher[/b], pas ici.\n"
		+ "5. Tout paiement en [color=#f97316]XMR[/color] ou [color=#f97316]BTC[/color] uniquement via escrow.\n\n"
		+ "[color=#ef4444]Violation de ces règles = ban permanent.[/color][/color]\n\n"
		+ _sep()
		+ _post("ghost_proc", "#22c55e", "il y a 6 mois",
			"Rappel utile. Beaucoup de nouveaux ces derniers temps qui oublient les bases.", "ghost_proc")
		+ _post("d4rk_n3t", "#22c55e", "il y a 3 mois",
			"Ajouter : ne jamais réutiliser une adresse XMR entre deux transactions.", "d4rk_n3t")
		+ _sep()
	)


# ═══════════════════════════════════════════════════
# PROFILS UTILISATEURS
# ═══════════════════════════════════════════════════
static func page_user_unknown() -> String:
	return (
		_header("Profil — UNKNOWN_▓▓▓")
		+ _nav()
		+ "[b][color=#ef4444]UNKNOWN_▓▓▓[/color][/b]\n"
		+ "[color=#484866]Membre depuis : ██████ · Posts : ▓▓▓ · Réputation : [color=#f97316]★★★★★[/color][/color]\n\n"
		+ _sep()
		+ "[color=#484866]Ce profil est masqué.\nContact via Cipher uniquement.[/color]\n\n"
		+ _sep()
	)


static func page_user_ghost() -> String:
	return (
		_header("Profil — ghost_proc")
		+ _nav()
		+ "[b][color=#22c55e]ghost_proc[/color][/b]\n"
		+ "[color=#484866]Membre depuis : 2023 · Posts : 312 · Réputation : [color=#f97316]★★★★☆[/color][/color]\n\n"
		+ _sep()
		+ "[color=#b0b0cc]Spécialiste : intrusion SSH, reconnaissance réseau.\n"
		+ "Auteur de ssh-bruteX. Disponible pour missions ponctuelles.[/color]\n\n"
		+ _sep()
	)


static func page_user_d4rk() -> String:
	return (
		_header("Profil — d4rk_n3t")
		+ _nav()
		+ "[b][color=#3b82f6]d4rk_n3t[/color][/b]\n"
		+ "[color=#484866]Membre depuis : 2021 · Posts : 891 · Réputation : [color=#f97316]★★★★★[/color][/color]\n\n"
		+ _sep()
		+ "[color=#b0b0cc]OSINT, cartographie réseau, reconnaissance passive.\n"
		+ "Ne prend pas de missions. Partage ses recherches gratuitement.[/color]\n\n"
		+ _sep()
	)


static func page_user_r00t() -> String:
	return (
		_header("Profil — r00t_k1t")
		+ _nav()
		+ "[b][color=#22c55e]r00t_k1t[/color][/b]\n"
		+ "[color=#484866]Membre depuis : 2022 · Posts : 156 · Réputation : [color=#f97316]★★★☆☆[/color][/color]\n\n"
		+ _sep()
		+ "[color=#b0b0cc]Pentest, exploitation de services mal configurés.\n"
		+ "Contributeur régulier sur r/tools. Disponible pour missions courtes.[/color]\n\n"
		+ _sep()
	)


static func page_user_proxy_null() -> String:
	return (
		_header("Profil — proxy_null")
		+ _nav()
		+ "[b][color=#22c55e]proxy_null[/color][/b]\n"
		+ "[color=#484866]Membre depuis : 2024 · Posts : 43 · Réputation : [color=#f97316]★★☆☆☆[/color][/color]\n\n"
		+ _sep()
		+ "[color=#b0b0cc]Exfiltration de données, pivot réseau.\n"
		+ "Relativement nouveau sur le forum. Cherche des missions pour monter en réputation.[/color]\n\n"
		+ _sep()
	)


static func page_user_anon() -> String:
	return (
		_header("Profil — anon_8821")
		+ _nav()
		+ "[b][color=#b0b0cc]anon_8821[/color][/b]\n"
		+ "[color=#484866]Membre depuis : 2023 · Posts : 78 · Réputation : [color=#f97316]★★★☆☆[/color][/color]\n\n"
		+ _sep()
		+ "[color=#b0b0cc]Sources internes, collecte d'informations passives.\n"
		+ "Ne prend pas de missions directes. Vend des informations exclusivement.[/color]\n\n"
		+ _sep()
	)


static func page_user_v0id() -> String:
	return (
		_header("Profil — v0id_run")
		+ _nav()
		+ "[b][color=#b0b0cc]v0id_run[/color][/b]\n"
		+ "[color=#484866]Membre depuis : 2022 · Posts : 201 · Réputation : [color=#f97316]★★★★☆[/color][/color]\n\n"
		+ _sep()
		+ "[color=#b0b0cc]Accès SSH, escalade de privilèges, exfiltration silencieuse.\n"
		+ "Profil discret, peu actif en public. Réputation basée sur des missions passées.[/color]\n\n"
		+ _sep()
	)


static func page_user_z3r0() -> String:
	return (
		_header("Profil — z3r0_tr4ce")
		+ _nav()
		+ "[b][color=#22c55e]z3r0_tr4ce[/color][/b]\n"
		+ "[color=#484866]Membre depuis : 2020 · Posts : 534 · Réputation : [color=#f97316]★★★★★[/color][/color]\n\n"
		+ _sep()
		+ "[color=#b0b0cc]Spécialiste en effacement de traces et anti-forensics.\n"
		+ "Auteur de LogWiper. Consultant sécurité opérationnelle (OPSEC).[/color]\n\n"
		+ _sep()
	)


# ═══════════════════════════════════════════════════
# PAGES UTILITAIRES
# ═══════════════════════════════════════════════════
static func page_login() -> String:
	return (
		_header("Connexion")
		+ _nav()
		+ "[b][color=#e0e0f0]  CONNEXION[/color][/b]\n\n"
		+ "[color=#484866]  Interface de connexion non disponible dans cette session.\n"
		+ "  Accès anonyme en lecture seule activé automatiquement.\n\n"
		+ "  Votre identité est protégée par le réseau TOR.[/color]\n\n"
		+ _sep()
	)


static func page_404(url: String) -> String:
	return (
		_header("Erreur")
		+ "[b][color=#ef4444]  404 — PAGE INTROUVABLE[/color][/b]\n\n"
		+ "[color=#484866]  L'adresse [color=#a855f7]" + url + "[/color] n'existe pas sur ce réseau.\n\n"
		+ "  [url=" + HOME + "][color=#a855f7]← Retour à l'accueil[/color][/url][/color]\n\n"
		+ _sep()
		+ "[color=#484866]  TOR · Nœud : NL-AMS-7 · Latence : 340ms[/color]\n"
	)
