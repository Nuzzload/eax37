# browser_boards.gd
# Pages d'accueil et de listing des boards du forum Dread.
class_name BrowserBoards


static func page_home() -> String:
	var H := BrowserPages.HOME
	return (
		BrowserPages.header()
		+ BrowserPages.nav()
		+ "[b][color=#e0e0f0]  TABLEAUX[/color][/b]\n\n"

		+ "  [url=" + H + "/r/jobs][b][color=#f97316][ JOBS ][/color][/b][/url]"
		+ "  [color=#b0b0cc]Contrats & missions rémunérées[/color]\n"
		+ "  [color=#484866]    23 fils · dernier post il y a 12 min[/color]\n\n"

		+ "  [url=" + H + "/r/tools][b][color=#22c55e][ OUTILS ][/color][/b][/url]"
		+ "  [color=#b0b0cc]Logiciels, scripts, exploits[/color]\n"
		+ "  [color=#484866]    47 fils · dernier post il y a 3h[/color]\n\n"

		+ "  [url=" + H + "/r/intel][b][color=#3b82f6][ INTEL ][/color][/b][/url]"
		+ "  [color=#b0b0cc]Cibles, réseaux, cartographies OSINT[/color]\n"
		+ "  [color=#484866]    31 fils · dernier post il y a 45 min[/color]\n\n"

		+ "  [url=" + H + "/r/comms][b][color=#7c3aed][ COMMS ][/color][/b][/url]"
		+ "  [color=#b0b0cc]Communication sécurisée, clés PGP[/color]\n"
		+ "  [color=#484866]    12 fils · dernier post il y a 2h[/color]\n\n"

		+ BrowserPages.sep()
		+ "[b][color=#e0e0f0]  FILS RÉCENTS[/color][/b]\n\n"

		+ "  [url=" + H + "/t/jobs/1][color=#f97316]▶[/color]"
		+ " [color=#b0b0cc][CONTRACT] Accès réseau corp. — paiement immédiat[/color][/url]\n"
		+ "  [color=#484866]    r/jobs · UNKNOWN_▓▓▓ · il y a 18 min · 4 rép.[/color]\n\n"

		+ "  [url=" + H + "/t/intel/1][color=#3b82f6]▶[/color]"
		+ " [color=#b0b0cc]EAX37 Corp — cartographie réseau 2026[/color][/url]\n"
		+ "  [color=#484866]    r/intel · d4rk_n3t · il y a 1h · 11 rép.[/color]\n\n"

		+ "  [url=" + H + "/t/tools/1][color=#22c55e]▶[/color]"
		+ " [color=#b0b0cc]ssh-bruteX v3.1 — wordlist 2026 mise à jour[/color][/url]\n"
		+ "  [color=#484866]    r/tools · ghost_proc · il y a 3h · 7 rép.[/color]\n\n"

		+ "  [url=" + H + "/t/jobs/2][color=#f97316]▶[/color]"
		+ " [color=#b0b0cc]ISO opérateur qualifié — exfiltration fichiers[/color][/url]\n"
		+ "  [color=#484866]    r/jobs · proxy_null · il y a 5h · 2 rép.[/color]\n\n"

		+ "  [url=" + H + "/t/intel/2][color=#3b82f6]▶[/color]"
		+ " [color=#b0b0cc]Dump credentials — serveur log compromis[/color][/url]\n"
		+ "  [color=#484866]    r/intel · anon_8821 · il y a 6h · 3 rép.[/color]\n\n"

		+ "  [url=" + H + "/t/intel/3][color=#3b82f6]▶[/color]"
		+ " [color=#b0b0cc]/etc/passwd leak — comptes actifs EAX37[/color][/url]\n"
		+ "  [color=#484866]    r/intel · v0id_run · il y a 8h · 5 rép.[/color]\n\n"

		+ BrowserPages.sep()
		+ "[color=#484866]  Connecté via TOR · Nœud de sortie : NL-AMS-7 · Latence : 340ms · Utilisateurs actifs : 47[/color]\n"
	)


static func page_board_jobs() -> String:
	var H := BrowserPages.HOME
	return (
		BrowserPages.header("r/jobs — Contrats & Missions")
		+ BrowserPages.nav()
		+ "[b][color=#f97316]  r/JOBS[/color][/b]   [color=#484866]Contrats, missions, paiements BTC/XMR[/color]\n"
		+ "[color=#ef4444]  ⚠ Utilisez toujours un intermédiaire. Aucun remboursement.[/color]\n\n"
		+ BrowserPages.sep()

		+ "  [url=" + H + "/t/jobs/1][b][color=#f97316][CONTRACT][/color]"
		+ " [color=#e0e0f0]Accès réseau corp. — paiement immédiat[/color][/b][/url]\n"
		+ "  [color=#484866]    UNKNOWN_▓▓▓ · il y a 18 min · [color=#22c55e]4 rép.[/color][/color]\n\n"

		+ "  [url=" + H + "/t/jobs/2][b][color=#f97316][ISO][/color]"
		+ " [color=#e0e0f0]Opérateur qualifié — exfiltration fichiers[/color][/b][/url]\n"
		+ "  [color=#484866]    proxy_null · il y a 5h · 2 rép.[/color]\n\n"

		+ "  [url=" + H + "/t/jobs/3][b][color=#484866][FERMÉ][/color]"
		+ " [color=#484866]Besoin accès SSH — résolu[/color][/b][/url]\n"
		+ "  [color=#484866]    v0id_run · il y a 2j · 9 rép.[/color]\n\n"

		+ BrowserPages.sep()
		+ "[color=#484866]  23 fils · Page 1/3[/color]\n"
	)


static func page_board_tools() -> String:
	var H := BrowserPages.HOME
	return (
		BrowserPages.header("r/tools — Outils & Exploits")
		+ BrowserPages.nav()
		+ "[b][color=#22c55e]  r/TOOLS[/color][/b]   [color=#484866]Scripts, frameworks, exploits partagés[/color]\n\n"
		+ BrowserPages.sep()

		+ "  [url=" + H + "/t/tools/1][b][color=#22c55e][RELEASE][/color]"
		+ " [color=#e0e0f0]ssh-bruteX v3.1 — wordlist 2026 incluse[/color][/b][/url]\n"
		+ "  [color=#484866]    ghost_proc · il y a 3h · 7 rép.[/color]\n\n"

		+ "  [url=" + H + "/t/tools/2][b][color=#22c55e][SCRIPT][/color]"
		+ " [color=#e0e0f0]nmap-auto — scan silencieux + rapport JSON[/color][/b][/url]\n"
		+ "  [color=#484866]    r00t_k1t · il y a 1j · 4 rép.[/color]\n\n"

		+ "  [url=" + H + "/t/tools/3][b][color=#22c55e][TOOL][/color]"
		+ " [color=#e0e0f0]LogWiper 2.0 — effacement traces système[/color][/b][/url]\n"
		+ "  [color=#484866]    z3r0_tr4ce · il y a 3j · 12 rép.[/color]\n\n"

		+ BrowserPages.sep()
		+ "[color=#484866]  47 fils · Page 1/5[/color]\n"
	)


static func page_board_intel() -> String:
	var H := BrowserPages.HOME
	return (
		BrowserPages.header("r/intel — Intelligence & Cibles")
		+ BrowserPages.nav()
		+ "[b][color=#3b82f6]  r/INTEL[/color][/b]   [color=#484866]OSINT, cartographies réseau, dumps[/color]\n"
		+ "[color=#ef4444]  ⚠ Ne postez que ce que vous avez obtenu vous-même.[/color]\n\n"
		+ BrowserPages.sep()

		+ "  [url=" + H + "/t/intel/1][b][color=#3b82f6][MAP][/color]"
		+ " [color=#e0e0f0]EAX37 Corp — cartographie réseau 2026[/color][/b][/url]\n"
		+ "  [color=#484866]    d4rk_n3t · il y a 1h · 11 rép.[/color]\n\n"

		+ "  [url=" + H + "/t/intel/2][b][color=#3b82f6][DUMP][/color]"
		+ " [color=#e0e0f0]Credentials serveur log compromis — 140 entrées[/color][/b][/url]\n"
		+ "  [color=#484866]    anon_8821 · il y a 6h · 3 rép.[/color]\n\n"

		+ "  [url=" + H + "/t/intel/3][b][color=#3b82f6][LEAK][/color]"
		+ " [color=#e0e0f0]/etc/passwd — comptes actifs EAX37[/color][/b][/url]\n"
		+ "  [color=#484866]    v0id_run · il y a 8h · 5 rép.[/color]\n\n"

		+ BrowserPages.sep()
		+ "[color=#484866]  31 fils · Page 1/4[/color]\n"
	)


static func page_board_comms() -> String:
	var H := BrowserPages.HOME
	return (
		BrowserPages.header("r/comms — Communication Sécurisée")
		+ BrowserPages.nav()
		+ "[b][color=#7c3aed]  r/COMMS[/color][/b]   [color=#484866]PGP, canaux sécurisés, dead drops[/color]\n\n"
		+ BrowserPages.sep()

		+ "  [url=" + H + "/t/comms/1][b][color=#7c3aed][PGP][/color]"
		+ " [color=#e0e0f0]Clé publique — UNKNOWN_▓▓▓[/color][/b][/url]\n"
		+ "  [color=#484866]    UNKNOWN_▓▓▓ · il y a 2j · 0 rép.[/color]\n\n"

		+ "  [url=" + H + "/t/comms/2][b][color=#7c3aed][OPSEC][/color]"
		+ " [color=#e0e0f0]Protocole communication — règles du forum[/color][/b][/url]\n"
		+ "  [color=#484866]    admin · épinglé · 34 rép.[/color]\n\n"

		+ BrowserPages.sep()
		+ "[color=#484866]  12 fils · Page 1/2[/color]\n"
	)
