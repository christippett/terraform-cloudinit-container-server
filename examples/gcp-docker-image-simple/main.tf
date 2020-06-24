module "docker-server" {
  source = "../.."

  domain            = "portainer.${var.domain}"
  letsencrypt_email = var.letsencrypt_email

  container = {
    image   = "portainer/portainer"
    command = "--admin-password ${replace(var.portainer_password, "$", "$$")}"
    ports   = ["9000"]
    volumes = ["/var/run/docker.sock:/var/run/docker.sock:ro"]
  }
}

/* Instance ----------------------------------------------------------------- */

resource "google_compute_instance" "portainer" {
  name         = "portainer"
  project      = var.project
  zone         = var.zone
  machine_type = "e2-small"
  tags         = ["ssh", "http-server", "https-server"]

  metadata = {
    user-data = module.docker-server.cloud_config
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.cos.self_link
    }
  }

  network_interface {
    subnetwork         = var.subnetwork_name
    subnetwork_project = var.project

    access_config {
      // Ephemeral IP
    }
  }
}

data "google_compute_image" "cos" {
  project = "cos-cloud"
  family  = "cos-81-lts"
}

/* DNS ---------------------------------------------------------------------- */

resource "google_dns_record_set" "portainer" {
  project      = var.project
  name         = "portainer.${var.domain}."
  managed_zone = var.cloud_dns_zone

  type    = "A"
  ttl     = 300
  rrdatas = [google_compute_instance.portainer.network_interface[0].access_config[0].nat_ip]
}
