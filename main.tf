locals {

  # Environment Variables --------------------------------------------------------

  ca = {
    prod    = "https://acme-v02.api.letsencrypt.orgdirectory"
    staging = "https://acme-staging-v02.api.letsencrypt.org/directory"
  }
  ca_server  = lookup(local.ca, var.ca_server, local.ca.staging)
  acme_email = coalesce(var.acme_email, "acme@${var.domain}")

  env = merge({
    DOMAIN    = var.domain
    PORT      = var.port
    IMAGE     = try(split(":", var.image)[0], "traefik/whoami")
    IMAGE_TAG = try(split(":", var.image)[1], "latest")

    TRAEFIK_VERSION                                         = "2.4"
    TRAEFIK_PROVIDERS_DOCKER_NETWORK                        = "app_default"
    TRAEFIK_CERTIFICATESRESOLVERS_letsencrypt_ACME_EMAIL    = local.acme_email
    TRAEFIK_CERTIFICATESRESOLVERS_letsencrypt_ACME_CASERVER = local.ca_server
  }, var.env)

  # Docker Compose ---------------------------------------------------------------

  tmpldir = "${path.module}/templates"

  compose_config = {
    version = "3"
    services = merge(
      yamldecode(file("${local.tmpldir}/compose/docker-compose.traefik.yaml")).services,
      yamldecode(file("${local.tmpldir}/compose/docker-compose.default.yaml")).services,
      { for name, s in var.services : name => merge({
        env_file = [".env"]
        labels = [
          "traefik.enable=true",
          "traefik.http.routers.${name}.entrypoints=https",
          "traefik.http.routers.${name}.tls.certresolver=letsencrypt",
          "traefik.http.routers.${name}.rule=Host(`${lookup(s, "domainname", "${name}.$${DOMAIN}")}`)"
        ] }, s)
      }
    )
  }

  # Cloud-Init Config ------------------------------------------------------------

  cloudinit = {
    runcmd = [<<-EOT
      echo "🐳 Installing Docker"
      which docker > /dev/null 2>&1 || curl -fsSL https://get.docker.com | sh
      EOT
      , <<-EOT
      echo "🚀 Starting application(s)"
      systemctl daemon-reload
      systemctl enable --now app config-monitor
      EOT
    ]

    write_files = flatten([
      {
        path     = "/var/app/.env"
        encoding = "b64"
        content  = base64encode(join("\n", [for k, v in local.env : "${k}=${v}"]))
      },
      {
        path     = "/var/app/traefik/traefik.yaml"
        encoding = "b64"
        content  = filebase64("${local.tmpldir}/traefik/traefik.yaml")
      },
      {
        path        = "/var/app/compose.sh"
        encoding    = "b64"
        permissions = "0755"
        content     = filebase64("${local.tmpldir}/compose.sh")
      },
      {
        path     = "/var/app/docker-compose.yaml"
        encoding = "b64"
        content  = base64encode(yamlencode(local.compose_config))
      },
      [for fp in fileset(local.tmpldir, "systemd/*") : {
        path     = "/etc/systemd/system/${basename(fp)}"
        encoding = "b64"
        content  = filebase64("${local.tmpldir}/${fp}")
      }],
      [for fp, content in var.files : {
        path        = "/var/app/${fp}"
        owner       = "app:users"
        permissions = substr(fp, -2, 2) == "sh" ? "0755" : "0644"
        encoding    = "b64"
        content     = base64encode(content)
      }]
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
    content      = "#cloud-config\n${yamlencode(var.cloud_config)}"
    content_type = "text/cloud-config"
    merge_type   = "list(append)+dict(no_replace,recurse_list)+str()"
  }
}
