# Docker Compose Anywhere

Docker Compose Anywhere is a template for hassle-free application hosting on a single, powerful server or VM.

## Motivation
Infrastructure don't have to be this hard e.g, K8s, cloud lingo, etc. Most applications can run reliably on a single server/VM, given how powerful they are these days. Your focus should be building product, not managing infrastructure. Docker compose is great for local development, but running docker compose in production is challenging due to downtime, this template addresses zero downtime deployment and setup all through github actions

## 🛠️ What this template offers?
- One-click Linux server setup with GitHub Actions
- Secure [SSH](https://github.com/appleboy/ssh-action) and [SCP](https://github.com/appleboy/scp-action) for seamless docker deployment and environment variable management
- Zero-downtime continuous deployment using GitHub Container Registry and [Docker Rollout](https://github.com/Wowu/docker-rollout)
- Effortless secrets management with GitHub Secrets, automatically copied to your VM/Server
- Continuous deployment through [Deploy action](https://github.com/hadijaveed/docker-compose-anywhere/blob/main/.github/workflows/deploy.yml#L12) for specified services on code merge
- Automated Postgres database backups via GitHub Action cron jobs
- Run multiple apps (e.g., Next.js, Python/Go servers) on a single VM
- Automated SSL setup with Traefik and Let's Encrypt (just add an A record to your DNS provider)

## Let's Get Started! 🚀

Follow these simple steps to set up your Docker Compose Anywhere environment:

### 1. Provision a VM (if you don't have one)

- Choose a cloud provider of your choice (e.g,DigitalOcean, Linode, AWS, GCP, or Hetzner)
- Select a supported Linux distribution (see [Docker's supported platforms](https://docs.docker.com/engine/install/#supported-platforms))
- Make sure only SSH access, HTTP and HTTPS ports are open for security

### 2. Generate SSH Key and Store in GitHub Secrets

1. Generate an SSH key locally:
   ```
   ssh-keygen -t rsa -b 4096 -C "<server-user-name>"
   ```

2. Either copy public key to your server through following command:
   ```
   ssh-copy-id user@your_server_ip
   ```

   or copy the public key to your server manually, and append it to `~/.ssh/authorized_keys` file

3. Copy private key to clipboard:
   - macOS: `pbcopy < ~/.ssh/id_rsa`
   - Linux: `xclip -sel clip < ~/.ssh/id_rsa`

4. Clone the Docker Compose Anywhere template:
   ```
   git clone https://github.com/hadijaveed/docker-compose-anywhere.git
   cd docker-compose-anywhere
   ```
5. Add the following GitHub repository secrets:
   - `SSH_KEY`: Paste private key
   - `HOST`: Server's public IP
   - `USER`: Server username

### 3. Initialize Your VM

1. Go to GitHub repository "Actions" tab
2. Find ["VM Initialization" workflow](https://github.com/hadijaveed/docker-compose-anywhere/actions/workflows/vm_init.yml)
3. Click "Run workflow"
4. Wait for successful completion
5. Upon completion, your server will have Docker and Docker Compose installed with all the correct permissions

### 4. Create .env File and Add to GitHub Secrets

1. Create `.env` file with app environment variables. You can use [`.env.sample`](https://github.com/hadijaveed/docker-compose-anywhere/blob/main/.env.sample) as a reference. Depending on your application and [docker-compose-prod](https://github.com/hadijaveed/docker-compose-anywhere/blob/main/docker-compose-prod.yml) setup you might need to add additional environment variables, adjust subdomains according to your domain setup, etc.
2. Add entire `.env` contents as **`ENV_FILE`** secret variable in github secrets

### 5. Make sure

1. Go to GitHub repository "Actions" tab
2. Find "Deploy to VM" workflow
3. Click "Run workflow"
4. Monitor deployment progress

🎉 Success! Your app should now be running on your VM.


