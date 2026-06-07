# Network Documentation

This document describes the current network and service layout of my homelab environment.

## Overview

The infrastructure is built around a reverse proxy setup with Traefik, Cloudflare Tunnel, internal DNS via AdGuard and several Docker-based services distributed across multiple VMs.

Main components:

- Reverse proxy: Traefik
- Public access: Cloudflare Tunnel
- Internal DNS: AdGuard
- Monitoring: Prometheus, Grafana, Uptime Kuma
- Automation: Semaphore / Ansible
- Core services: Nextcloud, Matrix, Jellyfin, Home Assistant



## Hosts

| Host | internal IP | Role | Notes |
|---|---|---|---|
| `rproxy` | 192.168.178.74 | Reverse Proxy | Traefik, Cloudflare Tunnel, matrix-wellknown |
| `nc` | 192.168.178.69 | Application Server | Nextcloud, MariaDB, Redis, Jellyfin |
| `mx` | 192.168.178.78 | Matrix Server | Synapse, Postgres |
| `adguard` | 192.168.178.76 | DNS Server | Internal DNS / DNS rewrites |
| `ha` | 192.168.178.75 | Home Automation | Home Assistant |
| `mon` | 192.168.178.77 | Monitoring | Prometheus, Grafana, Uptime Kuma, ntfy |
| `mgm` | 192.168.178.44 | Management | Semaphore / Ansible |

## Internal DNS

| DNS Name | Target | Service |
|---|---|---|
| `nc.node-forge.eu` | `nc` | Nextcloud |
| `ad.node-forge.eu` | `ad` | AdGuard |
| `ha.node-forge.eu` | `ha` | Home Assistant |
| `prox.node-forge.eu` | `rproxy` | Traefik Dashboard |
| `mon.node-forge.eu` | `mon` | Monitoring / Dashboard |

## Public Domains

| Domain | Service | Access Path |
|---|---|---|
| `node-forge.eu` | Main domain / Matrix well-known | Cloudflare Tunnel → Traefik |
| `nc.node-forge.eu` | Nextcloud | Cloudflare Tunnel → Traefik → Nextcloud |
| `matrix.node-forge.eu` | Matrix Synapse | Cloudflare Tunnel → Traefik → Synapse |
| `jellyfin.node-forge.eu` | jellyfin | Cloudflare Tunnel → Traefik → Jellyfin |
## Reverse Proxy Routing

| Entry | Routed To |
|---|---|
| Cloudflare Tunnel | Traefik |
| Traefik | Nextcloud |
| Traefik | Matrix Synapse |
| Traefik | Matrix well-known |
| Traefik | Jellyfin |
| Traefik | Home Assistant |
| Traefik | AdGuard |
| Traefik | Monitoring services |

## Monitoring

| Component | Purpose |
|---|---|
| Prometheus | Metrics collection |
| Grafana | Metrics dashboards |
| Uptime Kuma | Availability monitoring |
| Node Exporter | Host metrics |
| ntfy | Notifications |
| grafana-matrix-forwarder | Matrix alert forwarding |
| CrowdSec | Security / intrusion prevention |

## Management

| Component | Purpose |
|---|---|
| Semaphore | Web UI for Ansible |
| Ansible | Host configuration and automation |
| GitHub Repo | Versioned configuration files |

## Planned / Future Services

| Service | Purpose | state |
|---|---|---|
| Vaultwarden | Password manager | maybe |
| Stirling PDF | PDF tools, possibly integrated with Nextcloud | planned |
| Collabora Office | Nextcloud Office backend | planned |
| CrowdSec | Security / intrusion prevention | planned |
| SMART Monitoring | Disk health monitoring | planned (in bakup Script notify via matrix) |
| Matrix Bridges | WhatsApp, maybe Discord bridges | planned |
| cAdvisor | Container metrics |planned |

## Notes

- Public access should go through Cloudflare Tunnel and Traefik.
- Internal services should be resolved through AdGuard DNS rewrites.
- Secrets must stay in `.env` files and must not be committed.
- Service configuration should stay versioned in the GitHub repository.
