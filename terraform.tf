#Initialize Terraform
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS provider
provider "google" {
  region = "us-east-1"
}
# Creating a VPC
resource "google_compute_network" "first-vpc" {
 cidr_block = "10.0.0.0/16"
}

# Create an Internet Gateway
resource "google_compute_route" "proj-ig" {
 vpc_id = google_compute_network.first-vpc.id
 tags = {
 Name = "gateway1"
 }
}

# Setting up the route table
resource "google_compute_route" "proj-rt" {
 vpc_id = google_compute_network.first-vpc.id
 route {
 # pointing to the internet
 cidr_block = "0.0.0.0/0"
 gateway_id = google_compute_route.proj-ig.id
 }
 route {
 ipv6_cidr_block = "::/0"
 gateway_id = google_compute_route.proj-ig.id
 }
 tags = {
 Name = "rt1"
 }
}

# Setting up the subnet
resource "google_compute_subnetwork" "proj-subnet" {
 vpc_id = google_compute_network.first-vpc.id
 cidr_block = "10.0.1.0/24"
 availability_zone = "us-east-1b"
 tags = {
 Name = "subnet1"
 }
}

# Associating the subnet with the route table
resource "google_compute_route" "proj-rt-sub-assoc" {
subnet_id = google_compute_subnetwork.proj-subnet.id
route_table_id = google_compute_route.proj-rt.id
}

# Creating a Security Group
resource "google_compute_security_policy" "proj-sg" {
 name = "proj-sg"
 description = "Enable web traffic for the project"
 vpc_id = google_compute_network.first-vpc.id
 ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
 description = "HTTPS traffic"
 from_port = 443
 to_port = 443
 protocol = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
 }
 ingress {
 description = "HTTP traffic"
 from_port = 0
 to_port = 65000
 protocol = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
 }
 ingress {
 description = "Allow port 80 inbound"
 from_port   = 80
 to_port     = 80
 protocol    = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
  }
 egress {
 from_port = 0
 to_port = 0
 protocol = "-1"
 cidr_blocks = ["0.0.0.0/0"]
 ipv6_cidr_blocks = ["::/0"]
 }
 tags = {
 Name = "proj-sg1"
 }
}

# Creating a new network interface
resource "google_compute_network_interface" "proj-ni" {
 subnet_id = google_compute_network_subnet.proj-subnet.id
 private_ips = ["10.0.1.10"]
 security_groups = [google_compute_network_security_group.proj-sg.id]
}

# Attaching an elastic IP to the network interface
resource "google_compute_address" "proj-eip" {
 vpc = true
 network_interface = google_compute_network_interface.proj-ni.id
 associate_with_private_ip = "10.0.1.10"
}


# Creating an ubuntu EC2 instance
resource "google_compute_instance" "Test-Server" {
 ami = "elevated-style-415906"
 instance_type = "t2.micro"
 availability_zone = "us-east-1b"
 key_name = "gcp-key.pem"
 network_interface {
 device_index = 0
 network_interface_id = google_compute_network_interface.proj-ni.id
 }
 user_data  = <<-EOF
 #!/bin/bash
     sudo apt-get update -y
     sudo apt install docker.io -y
     sudo systemctl enable docker
     sudo docker run -itd -p 8085:8082 muzammilp/medicureimgtf8082:latest
     sudo docker start $(docker ps -aq)
 EOF
 tags = {
 Name = "Test-Server"
 }
}
