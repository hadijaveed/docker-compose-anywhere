If you already have SSH key, great! If not use the following instructions to generate one.

## Generating SSH key

Generate SSH key on your local unix system using the following command:

1. Generate SSH Key
```
ssh-keygen -t rsa -b 4096 -C "<user-nam>"
```
When prompted for paraphrase, either press enter or enter one. (It is recommended for added security) 

Either copy SSH public key to server, either manually or user following command:

2. Copy public key to your VM/server, replace your current user and host:
```
cat ~/.ssh/id_rsa.pub | ssh user@<host> 'cat >> .ssh/authorized_keys'
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

- Add it to Github Secrets SSH_KEY
- Add server host public IP to Github Secrets HOST
- Add username to Github Secrets USER
- Add paraphrase to Github Secrets PARAPHRASE, if you have added one

