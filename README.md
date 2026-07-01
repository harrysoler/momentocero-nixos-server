This project setup the linux server configuration for Momento Cero project. It uses the best practices in secret management and doubtful practices in linux user management.

# Setup

Create a pair of SSH keys for encrypting the secrets and accesing the server after deployed, we'll use it later.

To start enter to `configuration.nix` and define values for the following variables:

- `public-ssh-key`: The created SSH public key
- `momentocer-app-path`: Where to find the server files (make sure to match with path in folder `deploy-files`)
- `momentocero-port`: App port
- `momentocero-host`: App host
- `momentocero-db-host`: Database host
- `momentocero-db-name`: Database name
- `momentocero-db-user`: Database user

Next create the secrets for the server with the command `nix run github:ryantm/agenix -- -e ./secrets/<SECRET-FILE-NAME.age>`. The required secrets are in the file `./secrets/secrets.nix`, *you must use here your public key*.

Finally paste the project files in `./deploy-files/srv/momentocero/...` *and the created SSH keys in `./deploy-files/root/.ssh/...`* to be copied to the server.

# Deploy

To deploy the project to any server run the following command, it even deploys from any linux distro! (following that you have SSH root access):

```bash
nix run github:nix-community/nixos-anywhere -- --generate-hardware-config nixos-generate-config ./hardware-configuration.nix --flake .#momentocero --target-host root@<SERVER-IP> --extra-files ./deploy-files
```

If you need to change some config after deployed you can run the following:

```bash
nixos-rebuild boot --flake .#momentocero --target-host "root@<SERVER-IP>"
````
