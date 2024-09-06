# Docker Compose Anywhere

Docker Compose Anywhere is a template for hassle-free application hosting on a single, powerful server or VM.

## 💡 Motivation
Infrastructure don't have to be this hard e.g, not everything needs K8s, complex cloud setup, etc. Most applications can run reliably on a single server/VM, given how powerful they are these days.

Docker compose is great for local development, but running docker compose in production is challenging due to downtime, this template addresses zero downtime deployment and setup all through github actions

## 🛠️ What this template offers?
- One-click Linux server setup with GitHub Actions
- Secure [SSH](https://github.com/appleboy/ssh-action) and [SCP](https://github.com/appleboy/scp-action) for seamless docker deployment and environment variable management
- Zero-downtime continuous deployment using GitHub Container Registry and [Docker Rollout](https://github.com/Wowu/docker-rollout)
- Effortless secrets management with GitHub Secrets, automatically copied to your VM/Server
- Continuous deployment through [Deploy action](https://github.com/hadijaveed/docker-compose-anywhere/blob/main/.github/workflows/deploy.yml#L12) for specified services on code merge
- Automated Postgres database backups via GitHub Action [cron jobs](https://github.com/hadijaveed/docker-compose-anywhere/blob/main/.github/workflows/db-backup.yml)
- Run multiple apps (e.g., Next.js, Python/Go servers) on a single VM
- Automated SSL setup with [Traefik and Let's Encrypt](https://doc.traefik.io/traefik/user-guides/docker-compose/acme-tls/) (just add an A record to your DNS provider and you are all set)

## Let's Get Started! 🚀

Follow these simple steps to set up your Docker Compose Anywhere environment:

### 1. Provision a VM (if you don't have one)

- Choose a cloud provider of your choice (e.g,DigitalOcean, Linode, AWS, GCP, or Hetzner)
- Select a supported Linux distribution (see [Docker's supported platforms](https://docs.docker.com/engine/install/#supported-platforms))
- Make sure only SSH access, HTTP and HTTPS ports are open for security. 22, 80, 443

### 2. Generate SSH Key and Store in GitHub Secrets

1. Generate an SSH key locally:
   ```
   ssh-keygen -t rsa -b 4096 -C "<server-user-name>"
   ```

2. Copy public key to your server through following command or do it manually:
   ```
   ssh-copy-id user@your_server_ip
   ```

   or copy the public key to your server manually, and append it to **`~/.ssh/authorized_keys`** file on your server

3. Copy private key to clipboard:
   - macOS: `pbcopy < ~/.ssh/id_rsa`
   - Linux: `xclip -sel clip < ~/.ssh/id_rsa`

4. Add the following GitHub repository secrets:
   - **`SSH_KEY`**: Paste private key
   - **`HOST`**: Server's public IP
   - **`USER`**: Server username

5. Either clone the template or copy .github/workflows and environment files manually to your repository

### 3. Initialize Your VM

1. Go to GitHub repository "Actions" tab
2. Find ["VM Initialization" workflow](https://github.com/hadijaveed/docker-compose-anywhere/actions/workflows/vm_init.yml)
3. Click "Run workflow"
4. Wait for successful completion
5. Upon completion, your server will have Docker and Docker Compose installed with all the correct permissions

### 4. Create .env File and Add to GitHub Secrets

Development environment [example](https://github.com/hadijaveed/docker-compose-anywhere/blob/main/examples/environment)

1. Create `.env` file with app environment variables. You can use [`.env.sample`](https://github.com/hadijaveed/docker-compose-anywhere/blob/main/.env.sample) as a reference. Depending on your application and [docker-compose-deploy](https://github.com/hadijaveed/docker-compose-anywhere/blob/main/docker-compose-deploy.yml) setup you might need to add additional environment variables, adjust subdomains according to your domain setup, etc.
2. Add entire `.env` contents as **`ENV_FILE`** secret variable in github secrets

Following are the variables consumed by the github actions

| Secret Variable | Description |
|-----------------|-------------|
| `SSH_KEY` | The private SSH key for accessing your server |
| `HOST` | The public IP address or hostname of your server |
| `USER` | The username for SSH access to your server |
| `ENV_FILE` | The entire contents of your `.env` file, workflow will copy these to your server |
| `POSTGRES_USER` | Only consumed by database migration script |


### 5. Make docker-compose files ready and deploy

Use **docker-compose.yml** for local development and **docker-compose-deploy.yml** for production.

#### Local Development (docker-compose.yml)
- Use `docker-compose.yml` for consistent local development environment
- Modify services as needed for your project
- Adjust Traefik routing:
  - Update labels for your services, such as port and domain for traefik
  - Local development does not use tls
- Deploy pipeline will only build and push images for services that have `build` configuration in `docker-compose.yml`

#### Production Deployment (docker-compose-prod.yml)
- Use [`docker-compose-deploy.yml`](https://github.com/hadijaveed/docker-compose-anywhere/blob/main/docker-compose-deploy.yml) for server deployment
- Configure TLS in this file, it's already configured for traefik
- Update image names to use GitHub Packages:
  ```
  image: ghcr.io/{username-or-orgname}/{repository-name}/{service}:{version}
  ```
- Specify services for continuous deployment (e.g., web, api) in the [`SERVICES_TO_PUSH`](https://github.com/hadijaveed/docker-compose-anywhere/blob/main/.github/workflows/deploy.yml#L12) environment variable
- Keep infrastructure services (e.g., Traefik, PostgreSQL, Redis) separate from CI/CD pipeline, they are only mentioned as dependencies and compose will ensure they are always restarted

> **Note:** Ensure services that don't require CI/CD (like PostgreSQL, Redis, and Traefik) have dependencies set up properly. This is one of the limitations of [Docker Rollout]*(https://github.com/Wowu/docker-rollout?tab=readme-ov-file#%EF%B8%8F-caveats).

> **Note:** Define infrastructure services (e.g., PostgreSQL, Redis, Traefik) in your docker-compose file without CI/CD. List these as dependencies for your application services to ensure proper startup order during deployment. e.g, follow the [docker-compose-deploy.yml](https://github.com/hadijaveed/docker-compose-anywhere/blob/main/docker-compose-deploy.yml) file for reference.

### 6. Understanding the Deployment Process

The deployment script performs these key actions:
- Copies your `.env` file to the server
- Updates `docker-compose-prod.yml` on the server
- Deploys services with zero downtime:
  - Pulls latest images from GitHub Packages
  - Performs health checks
  - Rolls out updates without interruptions

## Quick Demo:
For quick demo you can follow my example site
- [App](https://app.hadijaveed.me/)
- [API](https://api.hadijaveed.me/ping)
- [Logs](https://dozzle.hadijaveed.me/)
- [Environment for server](https://github.com/hadijaveed/docker-compose-anywhere/blob/main/examples/environment)
- [Docker Composer Deployment](https://github.com/hadijaveed/docker-compose-anywhere/blob/main/docker-compose-deploy.yml)