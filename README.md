# Scripts & Config Files

Zentrale Sammlung meiner Skripte, Konfigurationsdateien und Automatisierungsprojekte für Linux-, Docker- und Homelab-Umgebungen.

## Repository Inhalt

Dieses Repository enthält Skripte, Konfigurationsdateien und Automatisierungen rund um Linux-, Docker- und Homelab-Umgebungen.

## Enthaltene Themen

### Ansible

Im Ordner `ansible/` befinden sich Playbooks und Konfigurationen für:

- Systemupdates
- Paketverwaltung
- Linux-Serververwaltung
- Automatisierung von Homelab-Systemen
- SSH- und Benutzerkonfigurationen

Beispielhafte Anpassungen können direkt in den jeweiligen Konfigurationsdateien vorgenommen werden.

```bash
ansible-playbook playbooks/updates.yml
```

---

### Docker

Im Ordner `docker/` befinden sich Container- und Stack-Konfigurationen für verschiedene Services und Homelab-Anwendungen.

Enthalten sind unter anderem:

- Docker Compose Stacks
- Service-Konfigurationen
- Monitoring
- Reverse Proxy
- Netzwerkdienste

---

## Verwendete Technologien

- Linux
- Docker
- Docker Compose
- Ansible
- Bash
- YAML
- Git & GitHub

---

## Nutzung

Repository klonen:

```bash
git clone https://github.com/axel5328/Scripts-Config-Files.git
cd Scripts-Config-Files
```

---

## Ziel des Repositories

Dieses Repository dient als:

- Backup wichtiger Konfigurationen
- Versionsverwaltung für Infrastruktur
- Sammlung wiederverwendbarer Skripte
- Homelab Dokumentation
- Automatisierungsplattform für Linux-Server

---

## Nutzungshinweise

Je nach Umgebung müssen Konfigurationen individuell angepasst werden.

Dazu gehören unter anderem:

- Eigene `.env` Dateien anlegen
- IP-Adressen und Hostnamen anpassen
- Volume- und Mountpfade anpassen
- Netzwerk- und DNS-Konfigurationen prüfen
- Zugangsdaten und Tokens selbst hinterlegen
- Docker Compose Dateien auf die eigene Umgebung abstimmen
- Ansible Inventory und Hosts anpassen

## Lizenz

MIT License

---

## Hinweis

Dieses Repository wird hauptsächlich für private Homelab-, Lern- und Testzwecke verwendet.

