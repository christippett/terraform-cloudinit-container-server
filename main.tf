data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "cloud-init.yaml"
    merge_type   = "list(append)+dict(no_replace,recurse_list)+str()"
    content_type = "text/cloud-config"
    content = templatefile("${local.dir}/cloud-config.yaml", {
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
  dir = "${path.module}/templates"

  template_compose_content = file("${local.dir}/docker-compose.default.yaml")
  template_compose_data    = yamldecode(local.template_compose_content)

  # do not merge fields that can defined as environment variables
  user_compose_data = {
    for k, v in var.container :
    k => v if ! contains(["image", "container_name", "command"], k)
  }

  # merge default Docker Compose template with values from `var.container`
  default_compose_data = {
    version = "3.3"
    services = {
      app = merge(local.template_compose_data.services.app, local.user_compose_data, {
        for key, val in local.template_compose_data.services.app : key =>
        can(tolist(val)) && contains(keys(local.user_compose_data), key)
        ? try(setunion(val, lookup(local.user_compose_data, key, [])), val)
        : lookup(local.user_compose_data, key, val)
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
    LETSENCRYPT_SERVER         = var.letsencrypt_staging ? "https://acme-staging-v02.api.letsencrypt.org/directory" : null
    IMAGE_NAME                 = try(split(":", var.container.image)[0], null)
    IMAGE_TAG                  = try(split(":", var.container.image)[1], "latest")
    CONTAINER_NAME             = lookup(var.container, "container_name", null)
    CONTAINER_COMMAND          = lookup(var.container, "command", null)
    CONTAINER_PORT             = lookup(var.container, "port", null)
    DOCKER_NETWORK             = "web"
    DOCKER_LOG_DRIVER          = null
    TRAEFIK_ENABLED            = null
    TRAEFIK_IMAGE_TAG          = null
    TRAEFIK_LOG_LEVEL          = null
    TRAEFIK_API_DASHBOARD      = null
    TRAEFIK_PASSWD_FILE        = null
    TRAEFIK_EXPOSED_BY_DEFAULT = null
    TRAEFIK_OPS_PORT           = null
    WEBHOOK_URL_PREFIX         = var.enable_webhook ? "hooks" : null
    WEBHOOK_HTTP_METHOD        = var.enable_webhook ? "PATCH" : null
  }, var.env)
  dot_env_content = join("\n", [for k, v in local.dot_env_data : "${k}=${v}" if v != null])

  compose_file_regex = "(?P<filename>docker-compose(?:\\.(?P<name>.*?))?\\.ya?ml)"

  webhook_files = var.enable_webhook ? [
    { filename = "docker-compose.webhook.yaml", content = filebase64("${local.dir}/docker-compose.webhook.yaml") },
    { filename = ".webhook/hooks.json", content = filebase64("${local.dir}/webook/hooks.json") },
    { filename = ".webhook/update-env.sh", content = filebase64("${local.dir}/webook/update-env.sh") }
  ] : []

  files = concat(
    [
      { filename = ".env", content = base64encode(local.dot_env_content) },
      { filename = "docker-compose.traefik.yaml", content = filebase64("${local.dir}/docker-compose.traefik.yaml") },
    ],
    # list of user-provided files to include (excl. docker-compose files)
    [for f in var.files : f if ! can(regex(local.compose_file_regex, f.filename))],
    # webhook related files (if enabled)
    local.webhook_files,
    # list of user-provided docker-compose files (if available)
    # if no docker-compose files are present, a default docker-compose file
    # will be included using values from `var.container`
    coalescelist(
      [for f in var.files : f if can(regex(local.compose_file_regex, f.filename))],
      [{ filename = "docker-compose.yaml", content = base64encode(local.default_compose_content) }]
    )
  )

  # list of Docker Compose files only, each file will have a corresponding
  # systemd service created
  docker_compose_files = [for f in local.files : merge(regex(local.compose_file_regex, f.filename), f) if can(regex(local.compose_file_regex, f.filename))]
}
