output "redis_instance_id" {
  description = "L'ID de la ressource Redis."
  value       = google_redis_instance.this.id
}

output "redis_host" {
  description = "Adresse IP de l'instance Redis."
  value       = google_redis_instance.this.host
}

output "redis_port" {
  description = "Port sur lequel Redis est accessible."
  value       = google_redis_instance.this.port
}

output "redis_read_endpoint" {
  description = "Adresse du endpoint en lecture (si read_replicas_mode=READ_REPLICAS_ENABLED)."
  value       = google_redis_instance.this.read_endpoint
}

output "redis_read_endpoint_port" {
  description = "Port du endpoint en lecture."
  value       = google_redis_instance.this.read_endpoint_port
}
