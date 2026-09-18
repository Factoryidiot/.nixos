# ./lib/nixos/monitoring.nix
{ config, pkgs, lib, ... }:
{
  # 1. Prometheus Metrics Engine & Scrapers
  services.prometheus = {
    enable = true;
    port = 9090;
    listenAddress = "0.0.0.0";
    retentionTime = "30d";

    # Native Exporters on host
    exporters = {
      node = {
        enable = true;
        port = 9100;
        listenAddress = "127.0.0.1";
        enabledCollectors = [ "systemd" ];
      };

      zfs = {
        enable = true;
        port = 9134;
        listenAddress = "127.0.0.1";
        pools = [ "tank" ];
      };

      smartctl = {
        enable = true;
        port = 9633;
        listenAddress = "127.0.0.1";
      };
    };

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = [ "127.0.0.1:9100" ];
            labels = { instance = "tahi"; };
          }
        ];
      }
      {
        job_name = "zfs";
        static_configs = [
          {
            targets = [ "127.0.0.1:9134" ];
            labels = { instance = "tahi"; };
          }
        ];
      }
      {
        job_name = "smartctl";
        static_configs = [
          {
            targets = [ "127.0.0.1:9633" ];
            labels = { instance = "tahi"; };
          }
        ];
      }
      {
        job_name = "incus";
        metrics_path = "/1.0/metrics";
        scheme = "https";
        tls_config = {
          insecure_skip_verify = true;
        };
        static_configs = [
          {
            targets = [ "127.0.0.1:9101" ];
            labels = { instance = "tahi"; };
          }
        ];
      }
    ];
  };

  # 2. Grafana Visualization & Dashboards
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3000;
        domain = "grafana.lan";
        root_url = "https://grafana.lan/";
      };
      security = {
        admin_user = "admin";
        secret_key = "$__file{/var/lib/grafana/secret_key}";
      };
    };

    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://127.0.0.1:9090";
          isDefault = true;
        }
      ];
    };
  };

  systemd.services.grafana.preStart = lib.mkBefore ''
    if [ ! -f /var/lib/grafana/secret_key ]; then
      mkdir -p /var/lib/grafana
      ${pkgs.openssl}/bin/openssl rand -base64 32 > /var/lib/grafana/secret_key
      chmod 400 /var/lib/grafana/secret_key
    fi
  '';

  # 3. Homepage Application Dashboard
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;
    allowedHosts = "tahi.lan,tahi.lan:443,172.16.1.200,172.16.1.200:8082,localhost:8082,127.0.0.1:8082";
    environmentFiles = [ "/persistent/var/lib/homepage/homepage.env" ];
  };

  systemd.services.homepage-dashboard = {
    environment.HOMEPAGE_CONFIG_DIR = lib.mkForce "/home/factory/.dotfiles/tahi/dashboard";
    serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "factory";
      Group = "users";
      ProtectHome = lib.mkForce "read-only";
      ProcSubset = lib.mkForce "all";
      BindReadOnlyPaths = [
        "-/home/factory/.dotfiles/tahi/dashboard"
      ];
    };
  };

  # Open firewall ports for Grafana and Homepage
  networking.firewall.allowedTCPPorts = [
    3000 # Grafana
    8082 # Homepage
    9090 # Prometheus
  ];
}
