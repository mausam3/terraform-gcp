provider "google" {
  project = "mausam-pandey"       # Replace with your GCP project ID
  region  = "us-central1"           # Replace with your desired region
  zone    = "us-central1-c"         # Replace with your desired zone
}

# Define the VPC Network
resource "google_compute_network" "jenkins_vpc" {
  name                    = "jenkins-vpc"
  auto_create_subnetworks  = false
}

# Define the Subnet
resource "google_compute_subnetwork" "jenkins_subnet" {
  name          = "jenkins-subnet"
  region        = "us-central1"
  network       = google_compute_network.jenkins_vpc.id
  ip_cidr_range = "10.0.0.0/24"  # Define your IP range here
}

# Define the Firewall Rule to Allow SSH and HTTP
resource "google_compute_firewall" "jenkins_firewall" {
  name    = "allow-ssh-http"
  network = google_compute_network.jenkins_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22", "80"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Define the VM instance for Jenkins
resource "google_compute_instance" "jenkins_vm" {
  name         = "jenkins-instance"
  machine_type = "n1-standard-1"   # Choose the machine type based on your requirements
  zone         = "us-central1-c"

  boot_disk {
    initialize_params {
      image = "ubuntu-2004-focal-v20210119"  # Ubuntu 20.04 LTS
    }
  }

  network_interface {
    network = google_compute_network.jenkins_vpc.id
    subnetwork = google_compute_subnetwork.jenkins_subnet.id
    access_config {
      // Ephemeral external IP for the instance
    }
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    # Install Jenkins on the VM
    sudo apt-get update
    sudo apt-get install -y openjdk-11-jre
    wget -q -O - https://pkg.jenkins.io/keys/jenkins.io.key | sudo apt-key add -
    sudo sh -c 'echo deb http://pkg.jenkins.io/debian/ stable main > /etc/apt/sources.list.d/jenkins.list'
    sudo apt-get update
    sudo apt-get install -y jenkins
    sudo systemctl start jenkins
    sudo systemctl enable jenkins
  EOT
}

# Output the external IP address of the Jenkins VM
output "jenkins_vm_ip" {
  value = google_compute_instance.jenkins_vm.network_interface[0].access_config[0].nat_ip
}
