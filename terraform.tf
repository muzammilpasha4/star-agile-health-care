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
  region      = "us-west4"
}

#resource "google_compute_network" "first-vpc" {
 # name                    = "first-vpc"
  #auto_create_subnetworks = false
#}

resource "google_compute_network" "first-vpc" {
  project                 = "my-project-name"
  name                    = "first-vpc"
  auto_create_subnetworks = true
}

#resource "google_compute_global_address" "proj-eip" {
 # name                  = "proj-eip"
  #address_type          = "INTERNAL"
  #purpose               = "PRIVATE_SERVICE_CONNECT"
  #project               = "elevated-style-415906"
  #network               = google_compute_network.first-vpc.id
#}

#resource "google_compute_subnetwork" "proj-subnet" {
 # name          = "proj-subnet"
 # ip_cidr_range = "10.0.1.0/16"
  #region        = "us-west4"
  #network       = google_compute_network.first-vpc.id
#}

#resource "google_compute_firewall" "proj-sg" {
 # name    = "proj-sg"
 # network = google_compute_network.first-vpc.id

 # allow {
 #   protocol = "tcp"
 #   ports    = ["80", "443","22","8085"]
 # }

 # allow {
  #  protocol = "icmp"
  #}

 # source_ranges = ["0.0.0.0/0"]
#}

resource "google_compute_instance" "Test-Server" {
  name         = "webserver"
  machine_type = "e2-micro"
  zone         = "us-west4-a"
  tags         = ["http-server", "all-ports"]

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20240208"
    }
  }
  network_interface {
    network = "default" # Default network to connect the virtual machine to
    access_config {
      # External IP address will be assigned automatically
    }
  }
  #network_interface {
    #network       = google_compute_network.first-vpc.id
   # subnetwork    = google_compute_subnetwork.proj-subnet.id
    #access_config {
  #    nat_ip = google_compute_global_address.proj-eip.address
    #}
# }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    sudo apt-get update -y
    sudo apt install docker.io -y
    sudo systemctl enable docker
    sudo docker run -itd -p 8085:8082 muzammilp/medicureimgtf8082:latest
    sudo docker start $(docker ps -aq)
  EOF
}
