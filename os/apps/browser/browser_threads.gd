# browser_threads.gd
# Pages de threads du forum Dread (jobs, tools, intel, comms).
class_name BrowserThreads


# ── JOBS ──────────────────────────────────────────

static func page_jobs_1() -> String:
	var H := BrowserPages.HOME
	return (
		BrowserPages.header("r/jobs › [CONTRACT] Accès réseau corp.")
		+ BrowserPages.nav()
		+ "[url=" + H + "/r/jobs][color=#a855f7]← retour r/jobs[/color][/url]\n\n"
		+ "[b][color=#f97316][CONTRACT][/color] [color=#e0e0f0]Accès réseau corp. — paiement immédiat[/color][/b]\n"
		+ "[url=" + H + "/u/unknown][color=#ef4444]UNKNOWN_▓▓▓[/color][/url]"
		+ "[color=#484866] · il y a 18 min · r/jobs[/color]\n"
		+ BrowserPages.sep()
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
		+ BrowserPages.sep()
		+ BrowserPages.post("r00t_k1t",    "#22c55e", "il y a 15 min", "Je suis dispo. Message envoyé.", "r00t_k1t")
		+ BrowserPages.post("ghost_proc",  "#22c55e", "il y a 12 min",
			"EAX37 ? Leur réseau est pas simple.\nT'as déjà un point d'entrée ?", "ghost_proc")
		+ BrowserPages.post("UNKNOWN_▓▓▓", "#ef4444", "il y a 10 min",
			"Opérateur trouvé. [b]Fil fermé aux nouvelles candidatures.[/b]", "unknown")
		+ BrowserPages.post("proxy_null",  "#22c55e", "il y a 3 min",
			"Trop tard alors. Bonne chance à l'heureux élu.", "proxy_null")
		+ BrowserPages.sep()
	)


static func page_jobs_2() -> String:
	var H := BrowserPages.HOME
	return (
		BrowserPages.header("r/jobs › ISO Opérateur qualifié")
		+ BrowserPages.nav()
		+ "[url=" + H + "/r/jobs][color=#a855f7]← retour r/jobs[/color][/url]\n\n"
		+ "[b][color=#f97316][ISO][/color] [color=#e0e0f0]Opérateur qualifié — exfiltration fichiers[/color][/b]\n"
		+ "[url=" + H + "/u/proxy_null][color=#22c55e]proxy_null[/color][/url]"
		+ "[color=#484866] · il y a 5h · r/jobs[/color]\n"
		+ BrowserPages.sep()
		+ "[color=#b0b0cc]Besoin d'un opérateur pour récupérer des documents sur un serveur distant.\n"
		+ "Serveur : Linux, accès SSH potentiellement disponible.\n"
		+ "Fichiers cibles : répertoire [color=#22c55e]/var/log/[/color]\n\n"
		+ "Paiement : [color=#f97316]0.8 BTC[/color] négociable selon profil.[/color]\n\n"
		+ BrowserPages.sep()
		+ BrowserPages.post("d4rk_n3t",  "#22c55e", "il y a 4h", "Intéressant. Quel OS côté serveur ?", "d4rk_n3t")
		+ BrowserPages.post("proxy_null", "#22c55e", "il y a 3h",
			"Ubuntu 22.04 d'après les headers. Pas de 2FA connu.", "proxy_null")
		+ BrowserPages.sep()
	)


static func page_jobs_3() -> String:
	var H := BrowserPages.HOME
	return (
		BrowserPages.header("r/jobs › [FERMÉ] Accès SSH")
		+ BrowserPages.nav()
		+ "[url=" + H + "/r/jobs][color=#a855f7]← retour r/jobs[/color][/url]\n\n"
		+ "[b][color=#484866][FERMÉ][/color] [color=#484866]Besoin accès SSH — résolu[/color][/b]\n"
		+ "[url=" + H + "/u/v0id_run][color=#b0b0cc]v0id_run[/color][/url]"
		+ "[color=#484866] · il y a 2 jours · r/jobs[/color]\n"
		+ BrowserPages.sep()
		+ "[color=#484866]Mission complétée. Merci à l'opérateur. Paiement envoyé.[/color]\n\n"
		+ BrowserPages.sep()
	)


# ── TOOLS ─────────────────────────────────────────

static func page_tools_1() -> String:
	var H := BrowserPages.HOME
	return (
		BrowserPages.header("r/tools › ssh-bruteX v3.1")
		+ BrowserPages.nav()
		+ "[url=" + H + "/r/tools][color=#a855f7]← retour r/tools[/color][/url]\n\n"
		+ "[b][color=#22c55e][RELEASE][/color] [color=#e0e0f0]ssh-bruteX v3.1 — wordlist 2026 incluse[/color][/b]\n"
		+ "[url=" + H + "/u/ghost_proc][color=#22c55e]ghost_proc[/color][/url]"
		+ "[color=#484866] · il y a 3h · r/tools[/color]\n"
		+ BrowserPages.sep()
		+ "[color=#b0b0cc]Mise à jour majeure.\n\n"
		+ "[b]Nouveautés v3.1 :[/b]\n"
		+ "  — Wordlist rockyou2026 intégrée (2.1M entrées)\n"
		+ "  — Mode silencieux (contourne fail2ban si délai ≥ 3s)\n"
		+ "  — Support IPv6\n"
		+ "  — Export rapport JSON\n\n"
		+ "[b]Usage :[/b]\n"
		+ "[color=#22c55e]  ./ssh-brutex -h <cible> -u <user> -w wordlist.txt --delay 4[/color]\n\n"
		+ "SHA256 : [color=#484866]a3f1b9c2d4e5f6a7b8c9d0e1f2a3b4c5[/color][/color]\n\n"
		+ BrowserPages.sep()
		+ BrowserPages.post("r00t_k1t",   "#22c55e", "il y a 2h",
			"Testé sur une cible privée. Délai 4s, aucune alerte. Efficace.", "r00t_k1t")
		+ BrowserPages.post("d4rk_n3t",   "#22c55e", "il y a 1h30",
			"La wordlist rockyou2026 est vraiment complète. Fortement recommandé.", "d4rk_n3t")
		+ BrowserPages.post("z3r0_tr4ce", "#22c55e", "il y a 1h",
			"Attention : certains SSH modernes bloquent après 3 tentatives même avec délai.\n"
			+ "Pensez à combiner avec un proxy rotatif.", "z3r0_tr4ce")
		+ BrowserPages.post("ghost_proc", "#22c55e", "il y a 45 min",
			"Bonne remarque. Prochaine version aura le support SOCKS5.", "ghost_proc")
		+ BrowserPages.sep()
	)


static func page_tools_2() -> String:
	var H := BrowserPages.HOME
	return (
		BrowserPages.header("r/tools › nmap-auto")
		+ BrowserPages.nav()
		+ "[url=" + H + "/r/tools][color=#a855f7]← retour r/tools[/color][/url]\n\n"
		+ "[b][color=#22c55e][SCRIPT][/color] [color=#e0e0f0]nmap-auto — scan silencieux + rapport JSON[/color][/b]\n"
		+ "[url=" + H + "/u/r00t_k1t][color=#22c55e]r00t_k1t[/color][/url]"
		+ "[color=#484866] · il y a 1j · r/tools[/color]\n"
		+ BrowserPages.sep()
		+ "[color=#b0b0cc]Wrapper bash pour nmap, génère un rapport JSON propre.\n\n"
		+ "[b]Usage :[/b]\n"
		+ "[color=#22c55e]  nmap-auto <ip> [--full] [--stealth] [--out rapport.json][/color]\n\n"
		+ "[b]Mode stealth :[/b] timing T1, fragmentation paquets, decoys aléatoires.\n"
		+ "Idéal pour éviter les IDS sur des cibles surveillées.[/color]\n\n"
		+ BrowserPages.sep()
		+ BrowserPages.post("anon_8821",  "#22c55e", "il y a 20h",
			"Fonctionne bien. J'ai scanné EAX37 avec --stealth, rien dans leurs logs.", "anon_8821")
		+ BrowserPages.post("z3r0_tr4ce", "#22c55e", "il y a 18h",
			"Pratique. Je l'ai branché sur un cron toutes les 6h pour du monitoring passif.", "z3r0_tr4ce")
		+ BrowserPages.post("r00t_k1t",   "#22c55e", "il y a 10h",
			"Nouvelle option --diff dans la prochaine version : compare deux scans et sort les changements.", "r00t_k1t")
		+ BrowserPages.sep()
	)


static func page_tools_3() -> String:
	var H := BrowserPages.HOME
	return (
		BrowserPages.header("r/tools › LogWiper 2.0")
		+ BrowserPages.nav()
		+ "[url=" + H + "/r/tools][color=#a855f7]← retour r/tools[/color][/url]\n\n"
		+ "[b][color=#22c55e][TOOL][/color] [color=#e0e0f0]LogWiper 2.0 — effacement traces système[/color][/b]\n"
		+ "[url=" + H + "/u/z3r0_tr4ce][color=#22c55e]z3r0_tr4ce[/color][/url]"
		+ "[color=#484866] · il y a 3j · r/tools[/color]\n"
		+ BrowserPages.sep()
		+ "[color=#b0b0cc]Efface proprement :\n"
		+ "  — /var/log/auth.log\n"
		+ "  — /var/log/syslog\n"
		+ "  — ~/.bash_history\n"
		+ "  — lastlog / wtmp / btmp\n\n"
		+ "[color=#ef4444]Requiert root.[/color]\n\n"
		+ "[color=#22c55e]  sudo ./logwiper --all --secure --zero-fill[/color]\n\n"
		+ "Option [color=#22c55e]--zero-fill[/color] : écrase avec des zéros avant suppression (forensics safe).[/color]\n\n"
		+ BrowserPages.sep()
		+ BrowserPages.post("ghost_proc",  "#22c55e", "il y a 2j",
			"Très utile après une op. J'utilise ça systématiquement.", "ghost_proc")
		+ BrowserPages.post("r00t_k1t",    "#22c55e", "il y a 2j",
			"Est-ce que ça gère aussi les logs journald ? systemd les stocke différemment.", "r00t_k1t")
		+ BrowserPages.post("z3r0_tr4ce",  "#22c55e", "il y a 1j",
			"Bonne remarque. Ajouté dans la v2.1 en cours :\n"
			+ "[color=#22c55e]journalctl --rotate && journalctl --vacuum-time=1s[/color]\n"
			+ "Disponible la semaine prochaine.", "z3r0_tr4ce")
		+ BrowserPages.sep()
	)


# ── INTEL ─────────────────────────────────────────

static func page_intel_1() -> String:
	var H := BrowserPages.HOME
	return (
		BrowserPages.header("r/intel › EAX37 Corp — réseau 2026")
		+ BrowserPages.nav()
		+ "[url=" + H + "/r/intel][color=#a855f7]← retour r/intel[/color][/url]\n\n"
		+ "[b][color=#3b82f6][MAP][/color] [color=#e0e0f0]EAX37 Corp — cartographie réseau 2026[/color][/b]\n"
		+ "[url=" + H + "/u/d4rk_n3t][color=#22c55e]d4rk_n3t[/color][/url]"
		+ "[color=#484866] · il y a 1h · r/intel[/color]\n"
		+ BrowserPages.sep()
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
		+ BrowserPages.sep()
		+ BrowserPages.post("ghost_proc", "#22c55e", "il y a 45 min",
			"Confirmé pour log-01. Port 22 répond bien, banner SSH visible.", "ghost_proc")
		+ BrowserPages.post("anon_8821",  "#22c55e", "il y a 30 min",
			"Le fichier cible est dans /var/log/secure d'après ma source interne.", "anon_8821")
		+ BrowserPages.post("r00t_k1t",   "#22c55e", "il y a 20 min",
			"Scan stealth effectué. Aucune réponse IDS. Timing T2 suffisant.", "r00t_k1t")
		+ BrowserPages.post("proxy_null", "#22c55e", "il y a 10 min",
			"Quelqu'un sait qui a le contrat sur ce réseau ?\nJ'ai vu passer un post dans r/jobs...", "proxy_null")
		+ BrowserPages.sep()
	)


static func page_intel_2() -> String:
	var H := BrowserPages.HOME
	return (
		BrowserPages.header("r/intel › Dump credentials")
		+ BrowserPages.nav()
		+ "[url=" + H + "/r/intel][color=#a855f7]← retour r/intel[/color][/url]\n\n"
		+ "[b][color=#3b82f6][DUMP][/color] [color=#e0e0f0]Credentials serveur log compromis — 140 entrées[/color][/b]\n"
		+ "[url=" + H + "/u/anon_8821][color=#b0b0cc]anon_8821[/color][/url]"
		+ "[color=#484866] · il y a 6h · r/intel[/color]\n"
		+ BrowserPages.sep()
		+ "[color=#b0b0cc]Dump partiel d'un /etc/shadow récupéré sur log-01.\n"
		+ "Format : user:hash\n\n"
		+ "[color=#22c55e]root:$6$rounds=5000$▓▓▓▓▓▓▓▓$▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓[/color]\n"
		+ "[color=#22c55e]hacker:$6$rounds=5000$▓▓▓▓▓▓▓▓$▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓[/color]\n"
		+ "[color=#22c55e]deploy:$6$rounds=5000$▓▓▓▓▓▓▓▓$▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓[/color]\n"
		+ "[color=#22c55e]sysadmin:$6$rounds=5000$▓▓▓▓▓▓▓▓$▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓[/color]\n\n"
		+ "[color=#ef4444]Hashes non crackés. Si quelqu'un a du temps GPU...[/color][/color]\n\n"
		+ BrowserPages.sep()
		+ BrowserPages.post("ghost_proc",  "#22c55e", "il y a 5h",
			"Le compte deploy a souvent des mots de passe faibles. À tenter en priorité.", "ghost_proc")
		+ BrowserPages.post("r00t_k1t",    "#22c55e", "il y a 4h",
			"En cours de crack avec hashcat. Je reviens si j'ai quelque chose.", "r00t_k1t")
		+ BrowserPages.post("z3r0_tr4ce",  "#22c55e", "il y a 2h",
			"Pas besoin de cracker si les credentials par défaut sont actifs.\n"
			+ "Essayez : admin:admin, deploy:deploy, hacker:hacker...", "z3r0_tr4ce")
		+ BrowserPages.sep()
	)


static func page_intel_3() -> String:
	var H := BrowserPages.HOME
	return (
		BrowserPages.header("r/intel › /etc/passwd leak — EAX37")
		+ BrowserPages.nav()
		+ "[url=" + H + "/r/intel][color=#a855f7]← retour r/intel[/color][/url]\n\n"
		+ "[b][color=#3b82f6][LEAK][/color] [color=#e0e0f0]/etc/passwd — comptes actifs EAX37[/color][/b]\n"
		+ "[url=" + H + "/u/v0id_run][color=#b0b0cc]v0id_run[/color][/url]"
		+ "[color=#484866] · il y a 8h · r/intel[/color]\n"
		+ BrowserPages.sep()
		+ "[color=#b0b0cc]Contenu /etc/passwd du serveur log-01.\n\n"
		+ "[color=#22c55e]root:x:0:0:root:/root:/bin/bash[/color]\n"
		+ "[color=#22c55e]daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin[/color]\n"
		+ "[color=#22c55e]hacker:x:1000:1000::/home/hacker:/bin/bash[/color]\n"
		+ "[color=#22c55e]deploy:x:1001:1001::/home/deploy:/bin/bash[/color]\n"
		+ "[color=#22c55e]sysadmin:x:1002:1002::/home/sysadmin:/bin/bash[/color]\n"
		+ "[color=#22c55e]backup:x:1003:1003::/var/backups:/bin/sh[/color]\n\n"
		+ "Comptes avec shell actif : root, hacker, deploy, sysadmin, backup[/color]\n\n"
		+ BrowserPages.sep()
		+ BrowserPages.post("anon_8821",  "#22c55e", "il y a 7h",
			"Le compte hacker est intéressant. Probablement un compte de test laissé actif.", "anon_8821")
		+ BrowserPages.post("ghost_proc", "#22c55e", "il y a 6h",
			"hacker:hacker est un classique. Quelqu'un a tenté ?", "ghost_proc")
		+ BrowserPages.post("v0id_run",   "#22c55e", "il y a 5h",
			"Essayé hacker:hacker et hacker:1234. Rien.\n"
			+ "Peut-être dans le dump shadow si quelqu'un crack les hashes.", "v0id_run")
		+ BrowserPages.post("proxy_null", "#22c55e", "il y a 3h",
			"On sait que quelqu'un a déjà le contrat sur cette cible.\n"
			+ "S'il réussit, il partagera peut-être les accès.", "proxy_null")
		+ BrowserPages.sep()
	)


# ── COMMS ─────────────────────────────────────────

static func page_comms_1() -> String:
	var H := BrowserPages.HOME
	return (
		BrowserPages.header("r/comms › Clé PGP — UNKNOWN_▓▓▓")
		+ BrowserPages.nav()
		+ "[url=" + H + "/r/comms][color=#a855f7]← retour r/comms[/color][/url]\n\n"
		+ "[b][color=#7c3aed][PGP][/color] [color=#e0e0f0]Clé publique — UNKNOWN_▓▓▓[/color][/b]\n"
		+ "[url=" + H + "/u/unknown][color=#ef4444]UNKNOWN_▓▓▓[/color][/url]"
		+ "[color=#484866] · il y a 2j · r/comms[/color]\n"
		+ BrowserPages.sep()
		+ "[color=#b0b0cc]Clé publique PGP pour communications chiffrées.\n"
		+ "Utilisez l'application Cipher pour les échanges directs et sécurisés.\n\n"
		+ "[color=#484866]-----BEGIN PGP PUBLIC KEY BLOCK-----\n"
		+ "Version: GnuPG v2.2.▓▓\n\n"
		+ "mQINBF▓▓▓▓▓▓BBAD▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓\n"
		+ "▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓\n"
		+ "=▓▓▓▓\n"
		+ "-----END PGP PUBLIC KEY BLOCK-----[/color][/color]\n\n"
		+ BrowserPages.sep()
	)


static func page_comms_2() -> String:
	var H := BrowserPages.HOME
	return (
		BrowserPages.header("r/comms › Protocole communication")
		+ BrowserPages.nav()
		+ "[url=" + H + "/r/comms][color=#a855f7]← retour r/comms[/color][/url]\n\n"
		+ "[b][color=#7c3aed][OPSEC][/color] [color=#e0e0f0]Protocole communication — règles du forum[/color][/b]\n"
		+ "[color=#484866]admin · épinglé · r/comms[/color]\n"
		+ BrowserPages.sep()
		+ "[b][color=#e0e0f0]Règles de communication sur ce forum :[/color][/b]\n\n"
		+ "[color=#b0b0cc]1. Toujours passer par TOR. Jamais de clearnet.\n"
		+ "2. Ne jamais donner d'informations personnelles identifiables.\n"
		+ "3. Utilisez PGP pour tout échange de données sensibles.\n"
		+ "4. Les coordinations de missions se font via [b]Cipher[/b], pas ici.\n"
		+ "5. Tout paiement en [color=#f97316]XMR[/color] ou [color=#f97316]BTC[/color] uniquement via escrow.\n\n"
		+ "[color=#ef4444]Violation de ces règles = ban permanent.[/color][/color]\n\n"
		+ BrowserPages.sep()
		+ BrowserPages.post("ghost_proc", "#22c55e", "il y a 6 mois",
			"Rappel utile. Beaucoup de nouveaux ces derniers temps qui oublient les bases.", "ghost_proc")
		+ BrowserPages.post("d4rk_n3t",   "#22c55e", "il y a 3 mois",
			"Ajouter : ne jamais réutiliser une adresse XMR entre deux transactions.", "d4rk_n3t")
		+ BrowserPages.sep()
	)
