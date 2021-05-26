resource "random_password" "traefik_admin" {
  count = var.traefik_admin_password == null ? 1 : 0
  length = 30
}

locals {
  letsencrypt_servers = {
    prod    = "https://acme-v02.api.letsencrypt.org/directory"
    staging = "https://acme-staging-v02.api.letsencrypt.org/directory"
  }

  traefik_admin_password = coalesce(
    var.traefik_admin_password,
    random_password.traefik_admin[0].result
  )

  # Docker Compose ---------------------------------------------------------------

  compose_re = "docker-(?:(\\w+)\\.)+ya?ml"
  image_re   = "(?:\\w+/)?(\\w+)(?:\\:\\w+)?" # namespace/image:tag

  # services should follow the same schema as defined in the docker-compose docs
  services = merge([
    for i, service in var.services : {
      # infer service name based on its image
      regex(local.image_re, service.image)[0] = merge(
        # the first service should use the root domain as its host
        { domainname = i == 1 ? var.domain : null }, service
      )
    }
  ]...)

  compose_config = {
    version  = "3"
    services = merge({
      for name, service in local.services : name => merge({
        restart  = "unless-stopped"
        env_file = [".env"]
        volumes  = ["/var/app:/app"]
        labels = [
          "traefik.enable=true",
          "traefik.http.routers.${name}.rule=Host(`${lookup(service, "domainname", "${name}.${var.domain}")}`)",
          "traefik.http.routers.${name}.entryPoints=websecure",
          "traefik.http.routers.${name}.tls.certresolver=letsencrypt"
        ]
      }, service)
    })
  }

    # Environment Variables --------------------------------------------------------

  env = merge({
    DOMAIN                 = var.domain
    DOCKER_NETWORK         = "web"
    TRAEFIK_VERSION        = "2.4"
    TRAEFIK_ADMIN_PORT     = 9000
    TRAEFIK_ADMIN_PASSWORD = bcrypt(local.traefik_admin_password, 6)
    LETSENCRYPT_EMAIL      = var.letsencrypt_email
    LETSENCRYPT_SERVER = lookup(
      local.letsencrypt_servers,
      var.letsencrypt_server,
      local.letsencrypt_servers.staging
    )
  }, var.environment)

  environment = join("\n", [ for key in sort(keys(local.env)) :
    "${key}=${lookup(local.env, key, "")}"
  ])

  # Cloud-Init Config ------------------------------------------------------------

  tmpdir = "${path.module}/templates"
  template_vars = local.env

  cloudinit = {
    runcmd = [<<-EOT
      echo "🐳 Installing Docker"
      which docker > /dev/null 2>&1 || curl -fsSL https://get.docker.com | sh
      if [ ! "$(docker network list -q --filter=name=${local.env.DOCKER_NETWORK})" ]; then
        docker network create ${local.env.DOCKER_NETWORK}
      fi
      EOT

      , <<-EOT
      echo "🚀 Starting application(s)"
      chmod a+x /var/app/run.sh
      systemctl enable --now \
        /var/app/systemd/app.service \
        /var/app/systemd/app-watcher.service
      EOT
    ]

    write_files = flatten([
      {
        path = "/var/app/.env"
        encoding = "b64"
        content = base64encode(local.environment)
      },
      {
        path     = "/var/app/docker-compose.override.yaml"
        encoding = "b64"
        content  = (
          length(local.services) > 0 ? base64encode(yamlencode(local.compose_config))
          : filebase64(var.docker_compose_file)
        )
      },
      [
        for fp in fileset(local.tmpdir, "**") : {
          path     = "/var/app/${fp}"
          encoding = "b64"
          content  = filebase64("${local.tmpdir}/${fp}")
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
    content      = "#cloud-config\n${yamlencode(local.cloudinit)}"
    content_type = "text/cloud-config"
    merge_type   = "list(append)+dict(no_replace,recurse_list)+str()"
  }

  part {
    content      = "#cloud-config\n${yamlencode(var.cloudinit)}"
    content_type = "text/cloud-config"
    merge_type   = "list(append)+dict(no_replace,recurse_list)+str()"
  }
}
