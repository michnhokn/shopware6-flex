{ pkgs, lib, config, ... }:

{
  packages = [
    pkgs.jq
    pkgs.gnupatch
  ];

  languages.javascript = {
    enable = lib.mkDefault true;
    package = lib.mkDefault pkgs.nodejs-16_x;
  };

  languages.php = {
    enable = lib.mkDefault true;
    version = lib.mkDefault "8.1";

     extensions = [
        "grpc"
        "mongodb"
        "amqp"
    ];

    ini = ''
      memory_limit = 2G
      upload_max_filesize = 100M
      post_max_size = 100M
      max_execution_time = 120
      realpath_cache_ttl = 3600J
      session.gc_probability = 0
      ${lib.optionalString config.services.redis.enable ''
      session.save_handler = redis
      session.save_path = "tcp://127.0.0.1:6379/0"
      ''}
      display_errors = On
      error_reporting = E_ALL
      assert.active = 0
      opcache.memory_consumption = 256M
      opcache.interned_strings_buffer = 20
      zend.assertions = 0
      short_open_tag = 0
      zend.detect_unicode = 0
      realpath_cache_ttl = 3600
    '';

    fpm.pools.web = lib.mkDefault {
      settings = {
        "clear_env" = "no";
        "pm" = "dynamic";
        "pm.max_children" = 10;
        "pm.start_servers" = 2;
        "pm.min_spare_servers" = 1;
        "pm.max_spare_servers" = 10;
      };
    };
  };

  services.caddy = {
    enable = lib.mkDefault true;

    virtualHosts.":8000" = lib.mkDefault {
      extraConfig = ''
        root * public
        php_fastcgi unix/${config.languages.php.fpm.pools.web.socket}
        encode zstd gzip
        file_server
        log {
          output stderr
          format console
          level ERROR
        }
      '';
    };
  };

  services.mysql = {
    enable = true;
    initialDatabases = lib.mkDefault [{ name = "shopware"; }];
    ensureUsers = lib.mkDefault [
      {
        name = "shopware";
        password = "shopware";
        ensurePermissions = {
          "shopware.*" = "ALL PRIVILEGES";
          "shopware_test.*" = "ALL PRIVILEGES";
        };
      }
    ];
    settings = {
      mysqld = {
        log_bin_trust_function_creators = 1;
      };
    };
  };

  services.redis.enable = lib.mkDefault true;
  services.adminer.enable = lib.mkDefault true;
  services.adminer.listen = lib.mkDefault "127.0.0.1:8010";
  services.mailhog.enable = lib.mkDefault true;
  services.mongodb.enable = true;
  services.rabbitmq = {
    enable = true;
    managementPlugin.enable = true;
  };

  #services.rabbitmq.managementPlugin.enable = true;
  #services.elasticsearch.enable = true;

  # Webpack compatibility
  env.NODE_OPTIONS = lib.mkDefault "--openssl-legacy-provider";
}
