
locals {
  config = {
    package_upgrade = true
    package_update  = true
    apt = {
      preserve_sources_list = true
      sources = {
        gcsfuse = {
          source = "deb http://packages.cloud.google.com/apt gcsfuse-focal main"
        }
      }
    }
    packages = ["gcsfuse"]
    runcmd = [
      "echo '🕵🏻‍♀️ Installing Google Logging Agent'",
      "curl -sSO https://dl.google.com/cloudagents/add-logging-agent-repo.sh",
      "bash add-logging-agent-repo.sh --also-install --structured --verbose",
      "service google-fluentd restart"
    ]
  }
}

data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "google-logging-agent.cfg"
    content      = join("\n", ["#cloud-config", yamlencode(local.config)])
    content_type = "text/cloud-config"
    merge_type   = "list(append)+dict(no_replace,recurse_list)+str()"
  }
}
