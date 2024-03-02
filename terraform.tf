terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}
provider "google" {
  credentials     = file("/home/bshaista154/GCP-ACCOUNT-ACCESS-KEY.json")
  project     = "elevated-style-415906"  
  region      = "us-east4"
}

resource "google_compute_network" "first-vpc" {
  name                    = "first-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_global_address" "proj-eip" {
  name                  = "proj-eip"
  address_type          = "INTERNAL"
  purpose               = "PRIVATE_SERVICE_CONNECT"
  project               = "elevated-style-415906"
  network               = google_compute_network.first-vpc.self_link

}

resource "google_compute_subnetwork" "proj-subnet" {
  name          = "proj-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-east4"
  network       = google_compute_network.first-vpc.self_link
}

resource "google_compute_firewall" "proj-sg" {
  name    = "proj-sg"
  network = google_compute_network.first-vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443","22","8085"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "Test-Server" {
  name         = "Test-Server"
  machine_type = "e2-micro"
  zone         = "us-east4-a"
  tags         = ["http-server", "https-server"]

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-22.04-lts"
    }
  }

  network_interface {
    network       = google_compute_network.first-vpc.self_link
    subnetwork    = google_compute_subnetwork.proj-subnet.self_link
    access_config {
      nat_ip = google_compute_global_address.proj-eip.address
    }
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    sudo apt-get update -y
    sudo apt install docker.io -y
    sudo systemctl enable docker
    sudo docker run -itd -p 8085:8082 muzammilp/medicureimgtf8082:latest
    sudo docker start $(docker ps -aq)
  EOF
}
