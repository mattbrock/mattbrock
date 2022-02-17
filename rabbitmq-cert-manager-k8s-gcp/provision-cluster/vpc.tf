variable "project_id" {
  description = "project id"
}

variable "zone" {
  description = "zone"
}

provider "google" {
  project = var.project_id
}

resource "google_compute_network" "vpc" {
  name = "test-vpc"
}
