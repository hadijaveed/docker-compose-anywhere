# Docker Compose Anywhere
Servers/VMs have become cheaper and really powerful, often during initial build of the product we are bogged down by complexity of setting up Cloud, K8s and others.

Docker compose is excellent tool for local development. But can it be used for production workloads? Yes, it can for initial build, plus scale to certain degree as your product grows. And once it grows engough you can swithc to more sopihisticated tools later

THis project aims to provide workflows to deploy docker compose to production
- Github action to setup a server or VM
- Seamless SCP / SSH into the server with packages
- Github action for (0 downtime)continuous deployment and setting up Github container registry
- Secrets management with Github secrets (Note: Secrets are not encrypted on the server yet, still work in progress)
- Continuous DB backups actions
- Alerting and monitoring


## So let's get started
First get a server or VM up and running. You can use any cloud provider (AWS EC2, GCP VM, Azure VM, Digital Ocean, Linode, etc) or even self hosted solution.

## 1. Generating SSH key

Generate SSH key on your local unix system using the following command:


**Note:** Always generate SSH keys on your local computer, not on the server. Generating keys on the server is not recommended for security reasons.

Here's how to generate an SSH key on your local machine:

1. Generate SSH Key
```
ssh-keygen -t rsa -b 4096 -C "<server-user-name>"
```
When prompted for paraphrase, either press enter or not enter one. (It is recommended for added security) 

Either copy SSH public key to server, either manually or user following command:

2. Copy public key to your VM/server, replace your current user and host:
```
cat ~/.ssh/id_rsa.pub | ssh server-user@<host> 'cat >> .ssh/authorized_keys'
```

3. Copy Private key and put in Github Secrets
```
# Ubuntu
sudo apt-get install xclip
```

copy private key to clipboard
```
# macOS
pbcopy < ~/.ssh/id_rsa
# Ubuntu
xclip < ~/.ssh/id_rsa
```

- Add it to Github Secrets **SSH_KEY**
- Add server host public IP to Github Secrets HOST
- Add username to Github Secrets USER
- Add paraphrase to Github Secrets **PARAPHRASE**, if you have added one

## 2. Run the Initialize VM workflow
Run the [Initialize VM workflow](.github/workflows/vm_init.yml) to set up Docker and Docker Compose on your server, and to get the VM ready

## 3. Define your docker compose files


