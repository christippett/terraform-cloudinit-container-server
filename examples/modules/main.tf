data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  dynamic "part" {
    for_each = flatten([
      module.docker.config,
      module.tailscale.config,
      module.shell.config
    ])

    content {
      filename     = part.value.filename
      content      = part.value.content
      content_type = part.value.content_type
      merge_type   = part.value.merge_type
    }
  }
}

resource "google_compute_instance" "example" {
  name         = var.config.name
  project      = var.config.project
  zone         = var.config.zone
  machine_type = "e2-medium"
  tags         = ["tailscale"]

  metadata = {
    user-data                  = data.cloudinit_config.config.rendered
    enable-oslogin             = "TRUE"
    serial-port-logging-enable = "TRUE"
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }

  network_interface {
    subnetwork         = var.config.subnet
    subnetwork_project = var.config.project
    access_config {}
  }

  scheduling {
    preemptible       = true
    automatic_restart = false
  }
}
