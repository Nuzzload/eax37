#!/usr/bin/env python3
# keylogger.py — capture silencieuse
# NE PAS LAISSER SUR DES MACHINES QUI NE M'APPARTIENNENT PAS

import sys
import os

LOG_FILE = "/tmp/.kl_cache"
TARGET = sys.argv[1] if len(sys.argv) > 1 else None

def capture(host):
    print(f"[*] Connexion à {host}...")
    # TODO: implémenter exfil via DNS pour éviter les firewalls
    pass

if __name__ == "__main__":
    if not TARGET:
        print("Usage: keylogger.py <host>")
        sys.exit(1)
    capture(TARGET)