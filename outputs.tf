output "id" {
  description = "The resource ID of the Redis instance."
  value       = google_redis_instance.this.id
}

output "host" {
  description = "The private IP address of the Redis instance."
  value       = google_redis_instance.this.host
}

output "port" {
  description = "The port on which Redis is listening."
  value       = google_redis_instance.this.port
}

output "read_endpoint" {
  description = "The IP address for read endpoint (if read replicas enabled)."
  value       = google_redis_instance.this.read_endpoint
}

output "read_endpoint_port" {
  description = "The port for read endpoint (if read replicas enabled)."
  value       = google_redis_instance.this.read_endpoint_port
}
