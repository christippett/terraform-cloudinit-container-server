data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "cloud-init.yaml"
    merge_type   = "list(append)+dict(no_replace,recurse_list)+str()"
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/templates/cloud-config.yaml", {
      files                = local.files
      docker_compose_files = local.docker_compose_files
    })
  }

  # the module accepts additional user-defined cloud-init config(s), these can
  # be useful for including custom commands to set up an instance - such as
  # configuring persistent disks or background tasks
  dynamic "part" {
    for_each = var.cloudinit_part
    content {
      merge_type   = "list(append)+dict(no_replace,recurse_list)+str()"
      content_type = part.value.content_type
      content      = part.value.content
    }
  }
}

locals {
  template_compose_content = file("${path.module}/templates/docker-compose.default.yaml")
  template_compose_data    = yamldecode(local.template_compose_content)

  # merge default Docker Compose template with values from `var.container`
  default_compose_data = {
    version = "3.3"
    services = {
      app = merge(local.template_compose_data.services.app, var.container, {
        for key, val in local.template_compose_data.services.app : key =>
        can(tolist(val)) && contains(keys(var.container), key)
        ? try(setunion(val, lookup(var.container, key, [])), val)
        : lookup(var.container, key, val)
      })
    }
    networks = {
      default = {
        external = {
          name = "$${DOCKER_NETWORK}"
        }
      }
    }
  }
  default_compose_content = yamlencode(local.default_compose_data)

  # other environment variables used by the Docker/Compose CLI can also be
  # defined here (https://docs.docker.com/compose/reference/envvars/)
  dot_env_data = merge({
    DOMAIN                     = var.domain
    LETSENCRYPT_EMAIL          = var.email
    LETSENCRYPT_SERVER         = var.letsencrypt_staging ? "https://acme-staging-v02.api.letsencrypt.org/directory" : "https://acme-v02.api.letsencrypt.org/directory"
    CONTAINER_IMAGE_NAME       = try(split(":", var.container.image)[0], null)
    CONTAINER_IMAGE_TAG        = try(split(":", var.container.image)[1], "latest")
    CONTAINER_WORKING_DIR      = lookup(var.container, "working_dir", "/app")
    CONTAINER_VOLUME_MOUNT     = "/app"
    CONTAINER_NAME             = lookup(var.container, "container_name", null)
    CONTAINER_COMMAND          = lookup(var.container, "command", null)
    CONTAINER_PORT             = lookup(var.container, "port", null)
    DOCKER_NETWORK             = "web"
    DOCKER_LOG_DRIVER          = "journald"
    TRAEFIK_ENABLED            = true
    TRAEFIK_IMAGE_TAG          = "v2.2"
    TRAEFIK_LOG_LEVEL          = "INFO"
    TRAEFIK_API_DASHBOARD      = false
    TRAEFIK_PASSWD_FILE        = "users"
    TRAEFIK_EXPOSED_BY_DEFAULT = true
    TRAEFIK_OPS_PORT           = 9000
  }, var.env)
  dot_env_content = join("\n", [for k, v in local.dot_env_data : "${k}=${v}" if v != null])

  compose_file_regex = "(?P<filename>docker-compose(?:\\.(?P<name>.*?))?\\.ya?ml)"
  files = concat(
    [{ filename = ".env", content = base64encode(local.dot_env_content) }],
    [{ filename = "users", content = filebase64("${path.module}/templates/users") }],
    [{ filename = "docker-compose.traefik.yaml", content = filebase64("${path.module}/templates/docker-compose.traefik.yaml") }],
    # list of user-provided files to include (excl. docker-compose files)
    [for f in var.files : f if ! can(regex(local.compose_file_regex, f.filename))],
    # list of user-provided docker-compose files to include (if available),
    # if no docker-compose files are present, a default docker-compose file
    # will be included and populated using values from `var.container`
    coalescelist(
      [for f in var.files : f if can(regex(local.compose_file_regex, f.filename))],
      [{ filename = "docker-compose.app.yaml", content = base64encode(local.default_compose_content) }]
    )
  )
  docker_compose_files = [for f in local.files : merge(regex(local.compose_file_regex, f.filename), f) if can(regex(local.compose_file_regex, f.filename))]
}
