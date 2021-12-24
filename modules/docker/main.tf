
locals {
  compose_version = coalesce(var.compose_version, "1.29.2")
  compose_v1      = length(regexall("1\\.[\\d\\.]+", local.compose_version)) > 0
  compose_url = format(
    "https://github.com/docker/compose/releases/download/%s/%s",
    local.compose_version,
    !local.compose_v1 ? "docker-compose-linux-$(uname -m)" : "run.sh"
  )

  config = {
    runcmd = compact([
      "command -v docker >/dev/null 2>&1 || curl -fsSL https://get.docker.com | sh",
      var.compose_version == null ? null : <<-EOT
      curl -fsSL "${local.compose_url}" -o /usr/local/bin/docker-compose &&
        chmod a+x /usr/local/bin/docker-compose
      EOT
    ])

    write_files = var.daemon_config == null ? [] : [{
      path     = "/etc/docker/daemon.json"
      encoding = "b64"
      content  = base64encode(jsonencode(var.daemon_config))
    }]

  }
}

