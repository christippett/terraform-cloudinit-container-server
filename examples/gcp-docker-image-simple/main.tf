module "container-server" {
  source = "../.."

  domain = "app.${var.domain}"
  email  = var.email

  container = {
    image = "nginxdemos/hello"
  }
}

/* Instance ----------------------------------------------------------------- */

resource "google_compute_instance" "app" {
  name         = "app"
  project      = var.project
  zone         = "${var.region}-a"
  machine_type = "e2-small"
  tags         = ["ssh", "http-server", "https-server"]

  metadata = {
    user-data = module.container-server.cloud_config
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.cos.self_link
    }
  }

  network_interface {
    subnetwork         = var.subnet_name
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

resource "google_dns_record_set" "app" {
  project      = var.project
  name         = "app.${var.domain}."
  managed_zone = var.cloud_dns_zone

  type    = "A"
  ttl     = 300
  rrdatas = [google_compute_instance.app.network_interface[0].access_config[0].nat_ip]
}
