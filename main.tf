locals {

  # Environment Variables --------------------------------------------------------

  letsencrypt = {
    prod    = "https://acme-v02.api.letsencrypt.orgdirectory"
    staging = "https://acme-staging-v02.api.letsencrypt.org/directory"
  }

  env = merge({
    DOCKER_NETWORK    = var.network
    DOMAIN            = var.domain
    APP_DIR           = var.appdir
    APP_PORT          = coalesce(var.port, "8080")
    APP_IMAGE_NAME    = try(split(":", var.image)[0], "nginx")
    APP_IMAGE_TAG     = try(split(":", var.image)[1], "latest")
    LETSENCRYPT_EMAIL = var.email
    LETSENCRYPT_SERVER = lookup(
      local.letsencrypt,
      var.letsencrypt_server,
      local.letsencrypt.staging
    )
    TRAEFIK_ENABLED   = true
    TRAEFIK_IMAGE_TAG = "2.4"
    TRAEFIK_OPS_PORT  = "9000"
    WEBHOOK_ENABLED   = var.webhook_enabled
  }, var.env)

  # Service Configuration --------------------------------------------------------

  compose_services = merge(

    // get default services
    {
      app = {
        container_name = "app"
        image          = coalesce(var.image, "$${APP_IMAGE_NAME}:$${APP_IMAGE_TAG:-latest}")
        restart        = "always"
        labels = [
          "traefik.http.routers.app.rule=Host(`${var.domain}`)",
          "traefik.http.services.app.loadbalancer.server.port=$${APP_PORT}"
        ]
      }
    },
    lookup(yamldecode(file("${local.tmpdir}/docker-compose.webhook.yaml")), "services", {}),
    lookup(yamldecode(file("${local.tmpdir}/docker-compose.traefik.yaml")), "services", {}),

    // find user services from docker-compose.* files and/or input variable
    merge(
      concat(
        [for fn, cfg in local.user_compose_files : lookup(cfg, "services", {})],
        [var.services]
      )
    ...)
  )

  # Docker Compose File ----------------------------------------------------------

  # pattern to get the rightmost number after ':'
  port_re = "^(?:(?:\\d+)?:)?(\\d+)$"

  compose_config = {
    version = 3.3
    services = {
      for name, svc in local.compose_services : name => merge(svc, {
        env_file = [".env"] # ensure this is added to every service
        labels = concat(
          lookup(svc, "labels", []),
          compact([
            "traefik.enable=true",
            # configure traefik port if only 1 port is defined and a label
            # doesn't already exist
            length(lookup(svc, "ports", [])) == 1
            && !anytrue([for label in lookup(svc, "labels", []) :
              length(regexall("loadbalancer\\.server\\.port", label)) > 0
            ])
            ? "traefik.http.services.${name}.loadbalancer.server.port=${
              try(regex(local.port_re, svc.ports[0])[0], svc.ports[0])
            }" : ""
          ]),
        )
      })
    }
    volumes = merge([
      for fn, cfg in local.user_compose_files : lookup(cfg, "volumes", {})
    ]...)
    networks = merge(
      { default = { external = { name = "$${DOCKER_NETWORK:-${var.network}}" } } },
      [for fn, cfg in local.user_compose_files : lookup(cfg, "networks", {})]...
    )
  }

  # Files / Assets ---------------------------------------------------------------

  tmpdir     = "${path.module}/templates"
  sysd       = "/etc/systemd/system"
  compose_re = "docker-compose(?:\\.(.+))?\\.ya?ml"

  user_compose_files = {
    for fn, c in var.files : fn => yamldecode(base64decode(c))
    if length(regexall(local.compose_re, fn)) > 0
  }

  files = merge(
    {
      "${local.sysd}/app.service"            = filebase64("${local.tmpdir}/app.service")
      "${local.sysd}/config-monitor.service" = filebase64("${local.tmpdir}/config-monitor.service")
      "${local.sysd}/config-monitor.path"    = filebase64("${local.tmpdir}/config-monitor.path")

      "$docker-compose.yaml"   = base64encode(yamlencode(local.compose_config))
      ".webhook/hooks.json"    = filebase64("${local.tmpdir}/webook/hooks.json")
      ".webhook/update-env.sh" = filebase64("${local.tmpdir}/webook/update-env.sh")
      ".env" = base64encode(
        join("\n", [for k, v in local.env : "${k}=${v}"])
      )
    }, var.files
  )
}

# Cloud-Init Config ------------------------------------------------------------

locals {
  cloudinit = {
    write_files = [for filename, content in local.files : {
      path        = "${var.appdir}/${filename}"
      permissions = substr(filename, -2, 2) == "sh" ? "0755" : "0644"
      content     = content
      encoding    = "b64"
    }]
    runcmd = [<<-EOT
      which docker > /dev/null 2>&1 || curl -fsSL https://get.docker.com | sh
      [ $(docker network list -q --filter=name=${var.network}) ] ||
        docker network create ${var.network}
      systemctl daemon-reload
      systemctl enable --now app config-monitor
    EOT
    ]
  }
}

data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  part {
    merge_type   = "list(append)+dict(no_replace,recurse_list)+str()"
    content_type = "text/cloud-config"
    content      = "#cloud-config\n${yamlencode(var.cloudinit_extra)}"
  }

  part {
    filename     = "cloud-init.yaml"
    merge_type   = "list(append)+dict(no_replace,recurse_list)+str()"
    content_type = "text/cloud-config"
    content      = "#cloud-config\n${yamlencode(local.cloudinit)}"
  }
}
