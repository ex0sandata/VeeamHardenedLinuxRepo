# VeeamHardenedLinuxRepo Setup Script


Dieses Skript setzt auf einen Blanken Ubuntu 20.04 und 22.04 Server ein Veeam Hardened Linux Repository auf und konfiguriert Optionale Sicherheitsschritte.

## Voraussetzungen
* Bestehender Veeam Backup and Replication Server (Version 11+)(Empfohlen: Enterprise Version für per-Machine Backup-Dateien)
* Ubuntu Server 20.04 und höher (Empfohlen: Physischer Server mit zwei logischen Festplatten: 1x für OS, 1x für Daten) 

## Vor ausführen des Skripts:

### Installation des Ubuntu Servers:
* Sprache: Englisch empfohlen
* Keyboard-Layout: Deutsch empfohlen
* OS-Partition mit ext4 formattieren OHNE LVM-Group
* (Ab Ubuntu 22.04: wenn möglich, minimale Installation anwählen)
* gegebenenfalls LACP Bond anlegen, wenn vorhanden, ansonsten Statische IPv4-Adresse konfigurieren
* --> Falls ein LACP Bond angelegt werden soll, möglichst in Bond Mode 4, alternativ in Bond Mode 0 / Round-Robin
* Hostname und normale User-Credentials festlegen (mittelstarkes Passwort)
* OpenSSH Server anwählen zur Installation
* Warten, bis alle Updates installiert sind und den Server neustarten (ISO auswerfen)

## Ausführen des Skripts:

