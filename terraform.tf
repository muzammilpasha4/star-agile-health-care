terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDkMltgEcPot7gifVSZljdvVVzdfU8Ja/I7dDpV9g4WL+MzF9fjDVbUL5yVpm78nYQy3oPvOoOLnH2kgvt4Rku5q1z5WznWTl83Gpa4G7ru6TLeJkBLQ79G2lM2xqGre+TCZBqdqtv0IX/FLHV+meojIVEqPu9MxtaCmYPOG7memVUhf5TBNWPCwgkrCuVAJH9UhP1r0zrhlkyvfN+koxwO9Q6WpEgXUA6w70TxcpWCHfH9sZD4jmScAwih0MnRQ42k4too7eutR4uys9PYp1p1QB/quEpgFK2IXSKK9c6hK9x93ZqtEKCUbMVk2uD/d+4J8fCYUqrUpfF24NhUDQ4/ bshaista154"
  project     = "elevated-style-415906"  
  region      = "us-central1"
}

resource "google_compute_network" "first-vpc" {
  name                    = "first-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_global_address" "proj-eip" {
  name                  = "proj-eip"
  address_type          = "EXTERNAL"
  purpose               = "GCE_ENDPOINT"
  prefix_length         = 32
  project               = "elevated-style-415906"
}

resource "google_compute_subnetwork" "proj-subnet" {
  name          = "proj-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"
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
    sudo docker run -itd -p 8085:8082 muzammilp/insuranceimgaddbook:latest
    sudo docker start $(docker ps -aq)
  EOF
}
