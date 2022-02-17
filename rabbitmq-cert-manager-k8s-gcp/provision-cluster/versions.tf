terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.52.0"
    }
  }

  required_version = ">= 0.14"

  backend "gcs" {
    # Change this to the bucket used to maintain state/lock
    bucket = "iac-state"
    prefix = "provision-cluster"
  }

}
