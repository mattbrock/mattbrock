output "zone" {
  value       = var.zone
  description = "Zone"
}

output "project_id" {
  value       = var.project_id
  description = "Project ID"
}

output "kubernetes_cluster_name" {
  value       = google_container_cluster.test.name
  description = "Cluster Name"
}

output "kubernetes_cluster_host" {
  value       = google_container_cluster.test.endpoint
  description = "Cluster Host"
}
