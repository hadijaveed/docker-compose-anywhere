# Docker Compose Anywhere

Docker Compose Anywhere is a template for hassle-free application hosting on a single, powerful server or VM.

🚀 Why Choose Docker Compose Anywhere Template?
- Utilize Docker Compose for both local development and production for consistent experience
- Simplify deployment with affordable, robust servers/VMs, avoiding cloud complexity
- Perfect for most applications, using web, api, background jobs, etc.
- Focus on building your product, not managing infrastructure (e.g, avoid K8s, cloud lingo, etc.)

🛠️ What this template Offer:
- One-click Linux server setup with GitHub Actions
- Secure [SSH](https://github.com/appleboy/ssh-action){:target="_blank"} and [SCP](https://github.com/appleboy/scp-action){:target="_blank"} for seamless docker deployment and copying environment variables + docker compose files
- Zero-downtime continuous deployment with GitHub Container Registry and [Docker Rollout](https://github.com/Wowu/docker-rollout){:target="_blank"}
- Effortless secrets management using GitHub Secrets. Github actions will copy your secrets to your VM/Server
- Continuous deployment through [Deploy action](https://github.com/hadijaveed/docker-compose-anywhere/blob/main/.github/workflows/deploy.yml#L12) for the services you want to deploy on code merge
- Automated database backups for Postgres for peace of mind through Github Action cron
- Run multiple apps (e.g., Next.js, Python/Go servers) on a single VM
- Automated SSL setup with Traefik and Let's Encrypt (just add an A record to your DNS provider)



For the most up-to-date list of supported Linux distributions, please refer to the [official Docker documentation on supported platforms](https://docs.docker.com/engine/install/#supported-platforms).



## Let's Get Started! 🚀

Follow these simple steps to set up your Docker Compose Anywhere environment:

### 1. Generate SSH Key and Store in GitHub Secrets

1. Generate an SSH key on your local machine:
   ```
   ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
   ```
   - Press Enter to accept the default file location
   - Optionally, set a passphrase for added security

2. Copy the public key to your server:
   ```
   ssh-copy-id user@your_server_ip
   ```

3. Copy the private key to your clipboard:
   - macOS: `pbcopy < ~/.ssh/id_rsa`
   - Linux: `xclip -sel clip < ~/.ssh/id_rsa`

4. Add the following secrets to your GitHub repository:
   - `SSH_KEY`: Paste the private key
   - `HOST`: Your server's public IP address
   - `USER`: Your server username

### 2. Initialize Your VM

1. Go to the "Actions" tab in your GitHub repository
2. Find the "VM Initialization" workflow
3. Click "Run workflow"
4. Wait for the workflow to complete successfully

### 3. Create .env File and Add to GitHub Secrets

1. Create a `.env` file with your application's environment variables
2. Add the entire contents of the `.env` file as a new secret named `ENV_FILE`

### 4. Run Deployment Script

1. Go to the "Actions" tab in your GitHub repository
2. Find the "Deploy to VM" workflow
3. Click "Run workflow"
4. Monitor the deployment progress

🎉 All done! Your application should now be up and running on your VM.


