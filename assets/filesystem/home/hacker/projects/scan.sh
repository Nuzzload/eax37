#!/bin/bash
# scan.sh — scan réseau rapide
# Usage: ./scan.sh <réseau/CIDR>

RANGE=${1:-"10.13.37.0/24"}
OUTPUT="scan_$(date +%Y%m%d_%H%M).txt"

echo "[*] Scan de $RANGE"
echo "[*] Résultats -> $OUTPUT"

nmap -sV -T4 --open "$RANGE" -oN "$OUTPUT" 2>/dev/null
echo "[+] Terminé."