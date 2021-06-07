locals {
  dir            = "${path.module}/templates"
  appdir         = "/var/app"
  docker_network = "traefik"

  letsencrypt_servers = {
    prod    = "https://acme-v02.api.letsencrypt.org/directory"
    staging = "https://acme-staging-v02.api.letsencrypt.org/directory"
  }
  letsencrypt_server = lookup(local.letsencrypt_servers, var.letsencrypt.server, "staging")

  traefik_admin = {
    user     = "admin"
    password = "traefik"
  }


  # Docker Compose ---------------------------------------------------------------

  default_compose_config = {
    version = "3"
    services = {
      default = {
        image    = coalesce(var.image, "traefik/whoami")
        restart  = "unless-stopped"
        env_file = [".env"]
        volumes  = ["${local.appdir}:/app"]
        labels = [
          "traefik.enable=true",
          "traefik.http.routers.default.rule=Host(`${var.domain}`)",
          "traefik.http.routers.default.entryPoints=websecure"
        ]
      }
    }
  }

  compose_config = coalesce(var.docker_compose, yamlencode(local.default_compose_config))

  # Environment Variables --------------------------------------------------------

  # Traefik configuration
  traefik_config = merge(
    {
      TRAEFIK_LOG_LEVEL      = "DEBUG"
      TRAEFIK_ACCESSLOG      = true
      TRAEFIK_API_DASHBOARD  = true
      TRAEFIK_ADMIN_USER     = local.traefik_admin.user
      TRAEFIK_ADMIN_PASSWORD = bcrypt(local.traefik_admin.password)

      TRAEFIK_PROVIDERS_DOCKER                  = true
      TRAEFIK_PROVIDERS_DOCKER_DEFAULTRULE      = "Host(`{{ index .Labels \"com.docker.compose.service\" }}.{{ env \"DOMAIN\" }}`)"
      TRAEFIK_PROVIDERS_DOCKER_EXPOSEDBYDEFAULT = true
      TRAEFIK_PROVIDERS_DOCKER_NETWORK          = local.docker_network
      TRAEFIK_PROVIDERS_FILE_DIRECTORY          = "/etc/traefik"

      TRAEFIK_CERTIFICATESRESOLVERS_letsencrypt                               = true
      TRAEFIK_CERTIFICATESRESOLVERS_letsencrypt_ACME_CASERVER                 = local.letsencrypt_server
      TRAEFIK_CERTIFICATESRESOLVERS_letsencrypt_ACME_EMAIL                    = var.letsencrypt.email
      TRAEFIK_CERTIFICATESRESOLVERS_letsencrypt_ACME_HTTPCHALLENGE            = true
      TRAEFIK_CERTIFICATESRESOLVERS_letsencrypt_ACME_HTTPCHALLENGE_ENTRYPOINT = "web"
      TRAEFIK_CERTIFICATESRESOLVERS_letsencrypt_ACME_STORAGE                  = "/acme/certs.json"

      TRAEFIK_ENTRYPOINTS_WEB                                        = true
      TRAEFIK_ENTRYPOINTS_WEB_ADDRESS                                = ":80"
      TRAEFIK_ENTRYPOINTS_WEB_HTTP_REDIRECTIONS_ENTRYPOINT_PERMANENT = true
      TRAEFIK_ENTRYPOINTS_WEB_HTTP_REDIRECTIONS_ENTRYPOINT_SCHEME    = "https"
      TRAEFIK_ENTRYPOINTS_WEB_HTTP_REDIRECTIONS_ENTRYPOINT_TO        = "websecure"

      TRAEFIK_ENTRYPOINTS_WEBSECURE                       = true
      TRAEFIK_ENTRYPOINTS_WEBSECURE_ADDRESS               = ":443"
      TRAEFIK_ENTRYPOINTS_WEBSECURE_HTTP_TLS              = true
      TRAEFIK_ENTRYPOINTS_WEBSECURE_HTTP_TLS_CERTRESOLVER = "letsencrypt"
    },
    { for k, v in var.environment : k => v if substr(k, 0, 8) == "TRAEFIK_" }
  )

  traefik_env = join("\n", [for k in sort(keys(local.traefik_config)) : "${k}=${local.traefik_config[k]}"])

  # Other environment variables
  env = merge(
    {
      APPDIR         = local.appdir
      DOCKER_NETWORK = local.docker_network
      DOMAIN         = var.domain
    },
    { for k, v in var.environment : k => v if substr(k, 0, 8) != "TRAEFIK_" }
  )
  user_env = join("\n", [for k in sort(keys(local.env)) : "${k}=${local.env[k]}"])

  # Cloud-Init Config ------------------------------------------------------------

  cloudinit = {
    runcmd = [<<-EOT
      echo "🐳 Installing Docker"
      which docker > /dev/null 2>&1 || curl -fsSL https://get.docker.com | sh
      if [ ! "$(docker network list -q --filter=name=${local.docker_network})" ]; then
        docker network create ${local.docker_network}
      fi
      EOT
      , <<-EOT
      echo "🚀 Starting application(s)"
      chmod a+x ${local.appdir}/run.sh
      systemctl enable --now \
        ${local.appdir}/systemd/app.service \
        ${local.appdir}/systemd/app-watcher.service
      EOT
    ]

    write_files = flatten([
      {
        path     = "${local.appdir}/.env"
        encoding = "b64"
        content  = base64encode(local.user_env)
      },
      {
        path     = "${local.appdir}/.env.traefik"
        encoding = "b64"
        content  = base64encode(local.traefik_env)
      },
      {
        path     = "${local.appdir}/docker-compose.override.yaml"
        encoding = "b64"
        content  = base64encode(local.compose_config)
      },
      [
        for fp in fileset(local.dir, "**") : {
          path     = "${local.appdir}/${fp}"
          encoding = "b64"
          content  = filebase64("${local.dir}/${fp}")
        }
      ]
    ])
  }
}

data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "init.cfg"
    content      = join("\n", ["#cloud-config", yamlencode(local.cloudinit)])
    content_type = "text/cloud-config"
    merge_type   = "list(append)+dict(no_replace,recurse_list)+str()"
  }

  dynamic "part" {
    for_each = var.cloudinit

    content {
      content      = join("\n", ["#cloud-config", yamlencode(part.value)])
      content_type = "text/cloud-config"
      merge_type   = "list(append)+dict(no_replace,recurse_list)+str()"
    }
  }
}
