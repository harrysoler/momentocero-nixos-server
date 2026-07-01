{ config, pkgs, pkgs-unstable, ... } @ args:
let
  public-ssh-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAmpmjpGJq+yBOfJGdBF2Ejnd/Wao3qBmi07gUXCjBMZ";

  momentocero-app-path = "/srv/momentocero";
  momentocero-port = 8501;
  momentocero-host = "127.0.0.1";

  momentocero-db-host = "localhost";
  momentocero-db-name = "momento_cero_santoto";
  momentocero-db-user = "root";

  momentocero-python-env = pkgs.python3.withPackages (ps: with ps; [
    accelerate
    kaleido # 0.2.1 talvez necesita 0.1.0
    matplotlib
    mysql-connector
    openpyxl
    pandas
    plotly
    seaborn
    streamlit
    torch
    transformers
    watchdog
    huggingface-hub
  ]);

in {
  imports = [ ./disk-config.nix ];
  disko.devices.disk.main.device = "/dev/vda";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  age.secrets = {
    hf-token.file = ./secrets/hf-token.age;
    db-password = {
      file = ./secrets/db-password.age;
      group = "docker";
      mode = "0440"; # permission to owner and group
    };
  };
  age.identityPaths = [ "/root/.ssh/id_ed25519" ];

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
      };

      efi.canTouchEfiVariables = true;
    };
  };

  networking.hostName = "momentocero";
  networking.firewall.allowedTCPPorts = [ 3306 ];

  environment.systemPackages = with pkgs; [
    gitMinimal
    sqlit-tui
    python314Packages.pymysql
  ] ++ [
    (pkgs.writeShellApplication {
      name = "momentocero-init-db";
    
      runtimeInputs = [ momentocero-python-env ]; 
    
      text = ''
        # shellcheck disable=SC1091
        source ${config.age.secrets.db-password.path}
        export MOMENTO_CERO_DB_PASSWORD

        export MOMENTO_CERO_DB_CREATE_DATABASE=1
        ${momentocero-python-env}/bin/python ${momentocero-app-path}/scripts/inicializar_db.py
      '';
    })
  ];


  services.openssh.enable = true;

  users.users.root = {
    openssh.authorizedKeys.keys = [
      public-ssh-key
    ];
    extraGroups = [ "docker" ];
  };

  systemd.tmpfiles.rules = [
    "Z ${momentocero-app-path} 0770 nobody nogroup - -"
  ];

  environment.sessionVariables = {
    MOMENTO_CERO_DB_USER = momentocero-db-user;
    MOMENTO_CERO_DB_NAME = momentocero-db-name;
    MOMENTO_CERO_DB_HOST = momentocero-db-host;
  };

  systemd.services.momentocero = {
    description = "Python deployed server for MomentoCero";
    after = [ "network.target" "docker.service" "docker-momentocero-db.service" ];
    requires = [ "docker-momentocero-db.service" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      MOMENTO_CERO_DB_USER = momentocero-db-user;
      MOMENTO_CERO_DB_NAME = momentocero-db-name;
      MOMENTO_CERO_DB_CREATE_DATABASE = "0";
      HF_TOKEN = "$(cat ${config.age.secrets.hf-token.path})";
    };

    serviceConfig = {
      Type = "simple";
      User = "root";
      Restart = "on-failure";
      RestartSec = "5s";

      EnvironmentFile = config.age.secrets.db-password.path;

      WorkingDirectory = momentocero-app-path;
      ExecStart = "${momentocero-python-env}/bin/streamlit run app.py --server.port ${builtins.toString momentocero-port} --server.address ${momentocero-host}";
    };
  };

  virtualisation.docker.enable = true;

  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      momentocero-db = {
        image = "mysql:8.4";
        ports = [ "3306:3306" ];
        environmentFiles = [
          config.age.secrets.db-password.path
        ];

        environment = {
          MYSQL_DATABASE = momentocero-db-name;
          MYSQL_ROOT_HOST= "%";
        };

        volumes = [
          "/var/lib/mysql:/var/lib/mysql"
        ];
      };
    };
  };

  system.stateVersion = "26.05";
}
