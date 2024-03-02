# ***************************** BEGIN: EDITING ENVIRONMENT VARIABLES *************************************************

# Define Environmental Variables
variable "credentials_file" { default = "/home/bshaista154/GCP-ACCOUNT-ACCESS-KEY.json" } # Copy the the service account credentials/authentication file (*.json) in the same folder with main terraform file
variable "project_id" { default = "elevated-style-415906" }             # Mention the Google Cloud project ID
variable "region" { default = "us-west4" }                              # Declare the default region where resources will be created
variable "zone" { default = "us-west4-a" }                              # Declare the default zone for the virtual machine
variable "vm_name" { default = "my-server" }                            # Declare the default name of the virtual machine
variable "machine_type" { default = "e2-medium" }                       # Declare the default machine type of the VM
variable "vm_count" { default = 1 }                                     # Declare the default No. of VM instance to be created
variable "disk_size_gb" { default = 10 }                                # Declare the default disk size in gigabytes for the VM
variable "provisioningModel" { default = "SPOT" }                       # Default provisioning model (Choose "SPOT" or "STANDARD") for the virtual machine
variable "network_tags" { default = ["http-server", "all-ports"] }      # Default network tags for the virtual machine

# Use this command to generate New Key Pair (ssh-keygen -t rsa -f ~/.ssh/<KEY_FILENAME> -C <USERNAME> -b 2048) Pls, replace <KEY_FILENAME> of your choice *.pem and <USERNAME> with your Ubuntu username.
variable "ssh_public_key" { default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDkMltgEcPot7gifVSZljdvVVzdfU8Ja/I7dDpV9g4WL+MzF9fjDVbUL5yVpm78nYQy3oPvOoOLnH2kgvt4Rku5q1z5WznWTl83Gpa4G7ru6TLeJkBLQ79G2lM2xqGre+TCZBqdqtv0IX/FLHV+meojIVEqPu9MxtaCmYPOG7memVUhf5TBNWPCwgkrCuVAJH9UhP1r0zrhlkyvfN+koxwO9Q6WpEgXUA6w70TxcpWCHfH9sZD4jmScAwih0MnRQ42k4too7eutR4uys9PYp1p1QB/quEpgFK2IXSKK9c6hK9x93ZqtEKCUbMVk2uD/d+4J8fCYUqrUpfF24NhUDQ4/ bshaista154" } # Paste your default SSH public-keyhere
variable "ssh_private_key" { default = "/home/bshaista154/gcp-key.pem" }                                                                                                                                                                                                                                                                                                                                                                                             # Copy the SSH Private key file (*.pem) in the same folder with MAIN terraform file
variable "ssh_username" { default = "bshaista154" }                                                                                                                                                                                                                                                                                                                                                                                                # Mention the username for the SSH key metadata

# Select OS image for the virtual machine (only uncomment one OS-image at a time)
variable "image" { default = "projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20240208" } # Ubuntu 22.04 LTS (Please set 10 GB disk space - required minimum)
#variable "image" { default = "projects/debian-cloud/global/images/debian-12-bookworm-v20240110" }               # Debian GNU / Linux-12 (Bookworm) (Please set 10 GB disk space - required minimum)
#variable "image" { default = "projects/centos-cloud/global/images/centos-7-v20240110" }                         # CentOS 7 (Please set 20 GB disk space - required minimum)
#variable "image" { default = "projects/rocky-linux-cloud/global/images/rocky-linux-9-optimized-gcp-v20240111" } # Rocky Linux 9 (Please set 20 GB disk space - required minimum)

# ***************************** ENDS: EDITING ENVIRONMENT VARIABLES *************************************************

# Define provider
provider "google" {
  credentials = file(var.credentials_file) # Use the service account credentials file for authentication
  project     = var.project_id             # Specify the Google Cloud project ID
  region      = var.region                 # Specify the region where resources will be created
}

# Create VM instance
resource "google_compute_instance" "vm_instance_1" {
  count        = var.vm_count                    # No. of VM instances to be created
  name         = "${var.vm_name}-${count.index}" # Name of the virtual machine instance
  machine_type = var.machine_type                # Type of machine to be used for the virtual machine
  scheduling {
    # Specify the provisioning model for the virtual machine
    automatic_restart   = false
    on_host_maintenance = "TERMINATE"
    preemptible         = true
    provisioning_model  = var.provisioningModel
  }
  zone = var.zone # Zone where the virtual machine will be located

  network_interface {
    network = "default" # Default network to connect the virtual machine to
    access_config {
      # External IP address will be assigned automatically
    }
  }
  tags = var.network_tags # Network tags for the virtual machine

  boot_disk {                  # Configuration for the boot disk of the virtual machine
    initialize_params {        # Parameters for initializing the boot disk
      image = var.image        # Image to be used for the operating system of the virtual machine
      size  = var.disk_size_gb # Size of the boot disk in gigabytes
    }
  }

  metadata = {
    "ssh-keys" = "${var.ssh_username}:${var.ssh_public_key}" # SSH key metadata with customizable username
  }

  #metadata_startup_script = <<-EOF
  #!/bin/bash
  # Add your bash commands or scripts here
  #cd /home
  #sudo wget https://raw.githubusercontent.com/prabhatraghav/html_test_page-repo/main/testscript.sh
  #sudo chmod +x /home/testscript.sh
  #sh /home/testscript.sh
  #echo "Hello, World!" >> /tmp/hello.txt
  # Example of running a script stored in Google Cloud Storage
  #gsutil cp gs://your-bucket-name/your-script.sh /tmp/your-script.sh
  #chmod +x /tmp/test_script.sh
  #/tmp/test_script.sh
  #EOF

  # Use the remote-exec provisioner to run commands on the instance
  provisioner "remote-exec" {
    inline = [
      # Here you can specify the commands you want to run on the instance.
      # For example, you could install a package, configure a service, or start a script.
      sudo apt-get update -y
      sudo apt install docker.io -y
      sudo systemctl enable docker
      sudo docker run -itd -p 8085:8082 muzammilp/medicureimgtf8082:latest
      sudo docker start $(docker ps -aq)    ]

    # Define the connection settings for the SSH connection to the instance
    connection {
      type        = "ssh"
      user        = ${var.ssh_username}
      private_key = ${var.ssh_private_key}
      host        = vm_instance_ip
    }
  }

}

# Fetch assigned IP of the VM instance
data "google_compute_instance" "vm_instance_data" {
  count      = var.vm_count
  name       = "${var.vm_name}-${count.index}" # Name of the virtual machine instances
  project    = var.project_id                  # Google Cloud project ID
  zone       = var.zone                        # Zone where the virtual machines are located
  depends_on = [google_compute_instance.vm_instance_1]
}

# Output VM instance IP address "vm_instance_ip"
output "vm_instance_ip" {
  value = [for instance in google_compute_instance.vm_instance_1 : instance.network_interface.0.access_config.0.nat_ip]
}

# Output VM instance name and IP address
output "vm_instance_ssh_command" {
  value = [
    for idx, instance in data.google_compute_instance.vm_instance_data :
    "ssh -i ${var.ssh_private_key} ${var.ssh_username}@${instance.network_interface.0.access_config.0.nat_ip}"
  ]
}

