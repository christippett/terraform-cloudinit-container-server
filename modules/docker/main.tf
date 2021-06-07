
locals {
  config = {
    apt = {
      preserve_sources_list = true
      sources = {
        docker = {
          source    = "deb https://download.docker.com/linux/ubuntu focal stable"
          keyid     = "0EBFCD88"
          keyserver = "https://download.docker.com/linux/ubuntu/gpg"
        }
        ctop = {
          source    = "deb http://packages.azlux.fr/debian/ buster main"
          keyid     = "0312D8E6"
          keyserver = "https://azlux.fr/repo.gpg.key"
        }
      }
    }
    package_upgrade = true
    package_update  = true
    packages        = ["docker-ctop"]

    write_files = var.daemon_config == null ? [] : [{
      path     = "/etc/docker/daemon.json"
      encoding = "b64"
      content  = base64encode(var.daemon_config)
    }]

    runcmd = [
      "echo '🐳 Installing Docker'",
      "which docker > /dev/null 2>&1 || curl -fsSL https://get.docker.com | sh"
    ]
  }
}

data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "docker.cfg"
    content      = join("\n", ["#cloud-config", yamlencode(local.config)])
    content_type = "text/cloud-config"
    merge_type   = "list(append)+dict(no_replace,recurse_list)+str()"
  }
}
