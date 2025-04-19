Simple script to backup a Supabase database

## Usage

Install Supabase CLI

```
npm install -g supabase
```

Install Docker

```
sudo apt update
sudo apt install -y docker.io
sudo systemctl enable --now docker
```

Copy `example.supabackup.env` to `.supabackup.env` and enter your supabase connection string and path to backups.

Setup cron

```
crontab -e
```

Example cron entry for 2am every day

```
0 2 * * * /usr/local/bin/backup_supabase.sh
```
