provider "google" {
  project = "my-gcp-project-id"
  region  = "us-central1"
  # credentials = file("path/to/serviceAccountKey.json")
}

# For CMEK or advanced features, you might need google-beta:
# provider "google-beta" {
#   project = "my-gcp-project-id"
#   region  = "us-central1"
#   # credentials = file("path/to/serviceAccountKey.json")
# }

module "my_redis" {
  source = "./modules/redis"

  project_id = "my-gcp-project-id"
  region     = "us-central1"
  name       = "my-redis-prod"

  tier            = "STANDARD_HA"
  memory_size_gb  = 2
  redis_version   = "REDIS_6_X"
  auth_enabled    = true

  # VPC
  authorized_network = "projects/my-gcp-project-id/global/networks/my-vpc"
  connect_mode       = "DIRECT_PEERING"

  # Maintenance window: Tuesday 03:00
  maintenance_day         = "TUESDAY"
  maintenance_start_hour  = 3
  maintenance_start_minute= 0

  # RDB Persistence, every 6 hours
  persistence_mode    = "RDB"
  rdb_snapshot_period = "SIX_HOURS"

  # CMEK (optional)
  kms_key_name = "projects/my-gcp-project-id/locations/us/keyRings/my-ring/cryptoKeys/my-redis-key"

  # Firewall for port 6379
  create_firewall          = true
  firewall_name            = "my-redis-firewall"
  firewall_source_ranges    = ["10.0.0.0/8","192.168.0.0/16"]
}

output "redis_host" {
  value = module.my_redis.redis_host
}
output "redis_port" {
  value = module.my_redis.redis_port
}
