
# Cloud-init modules -----------------------------------------------------------

module "tailscale" {
  source = "../../modules/tailscale"

  authkey             = var.tailscale.authkey
  advertise_exit_node = true
}

module "shell" {
  source = "../../modules/shell"

  users = {
    chris = {
      shell               = "/usr/bin/fish"
      sudo                = "ALL=(ALL) NOPASSWD:ALL"
      groups              = ["staff"]
      ssh_authorized_keys = [var.ssh_authorized_key]
    }
  }

  asdf = {
    plugins = ["ripgrep", "neovim", "bat", "fzf", "fd"]
  }
}

module "docker" {
  source = "../../modules/docker"

  daemon_config = {
    debug = true
  }
}

# Google OS images -------------------------------------------------------------

data "google_compute_image" "cos" {
  project = "cos-cloud"
  family  = "cos-81-lts"
}

data "google_compute_image" "ubuntu" {
  project = "ubuntu-os-cloud"
  family  = "ubuntu-2004-lts"
}
