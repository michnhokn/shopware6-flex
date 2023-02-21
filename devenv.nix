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
    ];

    ini = ''
      memory_limit = 2G
      realpath_cache_ttl = 3600
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

  #services.rabbitmq.enable = true;
  #services.rabbitmq.managementPlugin.enable = true;
  #services.elasticsearch.enable = true;

  # Environment variables
  env.APP_SECRET = lib.mkDefault "devsecret";
  env.APP_URL = lib.mkDefault "http://localhost:8000";
  env.MAILER_DSN = lib.mkDefault "smtp://localhost:1025";
  env.DATABASE_URL = lib.mkDefault "mysql://shopware:shopware@localhost:3306/shopware";
  env.MONGODB_CART_ENABLED = lib.mkDefault "1";
  env.MONGODB_URL = lib.mkDefault "mongodb://localhost:27017";
  env.CYPRESS_baseUrl = lib.mkDefault "http://localhost:8000";

  # Webpack compatibility
  env.NODE_OPTIONS = lib.mkDefault "--openssl-legacy-provider";

  # Shopware 6 related scripts
  scripts.build-js.exec = lib.mkDefault "bin/build-js.sh";
  scripts.build-storefront.exec = lib.mkDefault "bin/build-storefront.sh";
  scripts.watch-storefront.exec = lib.mkDefault "bin/watch-storefront.sh";
  scripts.build-administration.exec = lib.mkDefault "bin/build-administration.sh";
  scripts.watch-administration.exec = lib.mkDefault "bin/watch-administration.sh";
  scripts.theme-refresh.exec = lib.mkDefault "bin/console theme-refresh";
  scripts.theme-compile.exec = lib.mkDefault "bin/console theme-compile";

  # Symfony related scripts
  scripts.cc.exec = lib.mkDefault "bin/console cache:clear";
}
