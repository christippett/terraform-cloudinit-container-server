
locals {
  docker_compose_config = var.compose_file != null ? var.compose_file : yamlencode(local.default_config)
}

# terraform shares the same template syntax as docker compose's environment variable interpolation syntax

data "template_file" "docker_compose" {
  template = local.docker_compose_config
  vars = {
    letsencrypt_email = var.letsencrypt_email
    domain            = var.domain
  }
}

data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "cloud-init.yaml"
    content_type = "text/cloud-config"
    content = templatefile(
      "${path.module}/templates/cloud-config.yaml",
      {
        domain                     = var.domain
        docker_compose             = base64encode(data.template_file.docker_compose.rendered)
        enable_traefik_api         = var.enable_traefik_api
        enable_letsencrypt         = var.enable_letsencrypt
        letsencrypt_email          = var.letsencrypt_email
        letsencrypt_staging_server = var.letsencrypt_staging_server
        traefik_version            = var.traefik_version
        traefik_api_user           = var.traefik_api_user
        traefik_api_password       = var.traefik_api_password
        docker_log_driver          = var.docker_log_driver
        docker_log_opts            = jsonencode(var.docker_log_opts)
        files                      = [for f in var.files : f if can(base64decode(f.content))]
      }
    )
  }

  # allow supplemental cloud-init config(s) to be provided

  dynamic "part" {
    for_each = var.cloudinit_part
    content {
      content_type = part.value.content_type
      content      = part.value.content
   }
  }
}

# generate default docker compose config

locals {
  default_app_name = element(regex("^.*?/?([-_a-z0-9]+)(?::.*)?$", lookup(var.container, "image", "app")), 0)

  default_service = merge({
    image = "gcr.io/google-samples/hello-app:2.0"
    restart = "unless-stopped"
    ports = []
    labels = [
      "traefik.enable=true",
      "traefik.http.routers.${local.default_app_name}.rule=Host(`${var.domain}`)",
      "traefik.http.routers.${local.default_app_name}.entrypoints=websecure",
      "traefik.http.routers.${local.default_app_name}.tls=true",
      "traefik.http.routers.${local.default_app_name}.tls.certresolver=letsencrypt"
    ]
  }, var.container)

  default_config = {
    version = "3"
    services = {
      "${local.default_app_name}" = local.default_service
    }
    networks = {
      default = {
        external = {
          name = "web"
        }
      }
    }
  }
}
