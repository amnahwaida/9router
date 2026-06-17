# 9Router

Self-hosted reverse proxy dan API router dengan Cloudflare Tunnel untuk akses online yang aman.

## Arsitektur

```
Internet ──▶ Cloudflare Tunnel ──▶ 9Router (port 20128) ──▶ Backend Services
```

| Service            | Deskripsi                                      |
| ------------------ | ---------------------------------------------- |
| `9router`          | Reverse proxy & API router (port `20128`)      |
| `cloudflare-tunnel`| Cloudflare Tunnel untuk expose service ke internet |

## Struktur Folder

```
9router/
├── .env.example              # Template environment variables
├── .gitignore                # Proteksi file sensitif
├── docker-compose.yaml       # Konfigurasi Docker services
├── setup_claude_interactive.sh  # Setup Claude Code dengan custom endpoint
├── tunnel/
│   ├── Dockerfile            # Image cloudflared tunnel
│   └── entrypoint.sh         # Entrypoint dengan auto-detect online/offline
└── 9router-data/             # (runtime, tidak di-track git)
    ├── jwt-secret            # Auto-generated JWT secret
    ├── machine-id            # Auto-generated machine ID
    ├── db/                   # SQLite database
    ├── bin/                  # Binary (cloudflared)
    ├── logs/                 # Log files
    └── mitm/                 # MITM proxy config
```

## Prasyarat

- [Docker](https://docs.docker.com/get-docker/) & [Docker Compose](https://docs.docker.com/compose/install/)
- (Opsional) Cloudflare Tunnel token untuk akses online

## Instalasi

### 1. Clone repository

```bash
git clone https://github.com/amnahwaida/9router.git
cd 9router
```

### 2. Konfigurasi environment

```bash
cp .env.example .env
```

Edit file `.env` dan masukkan Cloudflare Tunnel token:

```env
TUNNEL_TOKEN=your_actual_tunnel_token_here
```

> Jika `TUNNEL_TOKEN` tidak diisi, tunnel akan berjalan dalam **mode offline** (LAN only).

### 3. Jalankan services

```bash
docker compose up -d
```

### 4. Verifikasi

```bash
# Cek status container
docker compose ps

# Cek logs
docker compose logs -f
```

9Router akan berjalan di `http://localhost:20128`.

## Mode Operasi

| Mode    | Kondisi                    | Akses                  |
| ------- | -------------------------- | ---------------------- |
| Online  | `TUNNEL_TOKEN` diisi       | Internet via Cloudflare |
| Offline | `TUNNEL_TOKEN` kosong/tidak ada | LAN only (`localhost:20128`) |

## Setup Claude Code (Opsional)

Script interaktif untuk mengkonfigurasi Claude Code agar menggunakan 9Router sebagai endpoint:

```bash
chmod +x setup_claude_interactive.sh
./setup_claude_interactive.sh
```

Script ini akan:
- Mengambil daftar model yang tersedia dari endpoint
- Memilih model untuk Opus, Sonnet, dan Haiku
- Menyimpan konfigurasi ke `~/.claude/settings.json`

## Perintah Berguna

```bash
# Start semua services
docker compose up -d

# Stop semua services
docker compose down

# Restart services
docker compose restart

# Lihat logs real-time
docker compose logs -f

# Rebuild tunnel image
docker compose build cloudflare-tunnel
```

## Keamanan

File-file berikut **tidak di-track** oleh git (dilindungi `.gitignore`):

- `.env` — berisi tunnel token
- `9router-data/jwt-secret` — JWT signing key
- `9router-data/machine-id` — unique machine identifier
- `9router-data/db/` — database SQLite
- `9router-data/bin/` — binary files

## Lisensi

MIT
