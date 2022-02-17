# Only one node for now to save costs - increase as needed
variable "num_nodes" {
  default     = 1
  description = "number of nodes"
}

# Create cluster and remove default node pool
resource "google_container_cluster" "test" {
  name     = "test-cluster"
  location = var.zone
  
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
}

# Create node pool for cluster
resource "google_container_node_pool" "test_nodes" {
  name       = "test-nodes"
  location   = var.zone
  cluster    = google_container_cluster.test.name
  node_count = var.num_nodes

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = "test"
    }

    # e2-standard-2 seems to be the minimum required by the RabbitMQ cluster
    # - change as needed
    machine_type = "e2-standard-2"
    tags         = ["test-node"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}
