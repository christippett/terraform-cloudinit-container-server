module "docker-server" {
  source = "../.."

  domain       = var.domain
  compose_file = file("${path.cwd}/docker-compose.yaml")

  enable_letsencrypt = true
  letsencrypt_email  = var.letsencrypt_email

  enable_traefik_api   = true
  traefik_api_user     = var.traefik_api_user
  traefik_api_password = var.traefik_api_password

  # https://docs.docker.com/config/containers/logging/gcplogs/
  docker_log_driver = "gcplogs"
  docker_log_opts   = { gcp-log-cmd = "true" }

  # custom instance configuration can be provided by providing supplemental cloud-init config(s)
  cloudinit_part = [{
    content_type = "text/cloud-config"
    content = local.cloudinit_disk
  }]
}

# prepare persistent disk

locals {
  cloudinit_disk = <<EOT
#cloud-config

bootcmd:
  - fsck.ext4 -tvy /dev/sdb || mkfs.ext4 /dev/sdb
  - mkdir -p /run/app
  - mount -o defaults -t ext4 /dev/sdb /run/app

EOT
}


/* Instance ----------------------------------------------------------------- */

resource "google_compute_instance" "app_server" {
  name          = "app-server"
  project       = var.project
  zone          = var.zone
  machine_type  = "e2-small"
  tags          = ["ssh", "http-server", "https-server"]

  metadata = {
    user-data = module.docker-server.cloud_config
  }

  service_account {
    email  = google_service_account.default.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
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
      nat_ip = google_compute_address.static.address
    }
  }

  scheduling {
    automatic_restart = true
  }

  allow_stopping_for_update = true

  lifecycle {
    ignore_changes = [attached_disk]
  }
}

data "google_compute_image" "cos" {
  project = "cos-cloud"
  family  = "cos-81-lts"
}

/* Disk --------------------------------------------------------------------- */

resource "google_compute_disk" "default" {
  project = var.project
  name    = "disk-app-server"
  type    = "pd-standard"
  zone    = var.zone
  size    = 10
}

resource "google_compute_attached_disk" "default" {
  disk     = google_compute_disk.default.id
  instance = google_compute_instance.app_server.id
}

/* Network ------------------------------------------------------------------ */

resource "google_compute_address" "static" {
  project      = var.project
  region       = var.region
  name         = "ip-app-server"
  network_tier = "PREMIUM"
}

/* DNS ---------------------------------------------------------------------- */

resource "google_dns_record_set" "default" {
  project      = var.project
  name         = "${var.domain}."
  managed_zone = var.cloud_dns_zone

  type    = "A"
  ttl     = 300
  rrdatas = [google_compute_address.static.address]
}

resource "google_dns_record_set" "wildcard" {
  project      = var.project
  name         = "*.${var.domain}."
  managed_zone = var.cloud_dns_zone

  type    = "A"
  ttl     = 300
  rrdatas = [google_compute_address.static.address]
}

/* IAM ---------------------------------------------------------------------- */

resource "google_service_account" "default" {
  account_id   = "app-server"
  display_name = "Application Service Account"
  project      = var.project
}

resource "google_project_iam_member" "default" {
  project  = var.project
  role     = "roles/logging.logWriter"
  member   = "serviceAccount:${google_service_account.default.email}"
}
