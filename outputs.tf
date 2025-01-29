output "instance_id" {
  description = "L'ID unique de la ressource Redis sur GCP"
  value       = google_redis_instance.this.id
}

output "host" {
  description = "Adresse IP de l'instance Redis (dans le VPC spécifié)"
  value       = google_redis_instance.this.host
}

output "port" {
  description = "Port sur lequel Redis est exposé"
  value       = google_redis_instance.this.port
}

output "transit_encryption_mode" {
  description = "Le mode de chiffrement en transit effectif"
  value       = google_redis_instance.this.transit_encryption_mode
}

output "auth_enabled" {
  description = "L'authentification est-elle activée ?"
  value       = google_redis_instance.this.auth_enabled
}

output "read_endpoint" {
  description = "Adresse du endpoint en lecture (si read_replicas_mode = READ_REPLICAS_ENABLED)"
  value       = google_redis_instance.this.read_endpoint
}

output "read_endpoint_port" {
  description = "Port du endpoint en lecture"
  value       = google_redis_instance.this.read_endpoint_port
}
