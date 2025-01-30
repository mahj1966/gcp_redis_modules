provider "google" {
  project = "my-gcp-project"
  region  = "us-central1"
  # credentials = file("path/to/key.json") # if using a service account
}

module "my_redis" {
  source = "./modules/redis"

  project_id = "my-gcp-project"
  region     = "us-central1"
  name       = "my-redis-prod"

  tier           = "STANDARD_HA"
  memory_size_gb = 2
  redis_version  = "REDIS_6_X"

  authorized_network = "projects/my-gcp-project/global/networks/my-custom-network"
  connect_mode       = "DIRECT_PEERING"
  auth_enabled       = true

  # Example: read replicas
  read_replicas_mode = "READ_REPLICAS_ENABLED"
  replica_count      = 2

  # Maintenance window: Tuesday at 03:15 UTC
  maintenance_day         = "TUESDAY"
  maintenance_start_hour  = 3
  maintenance_start_minute= 15

  # RDB Persistence
  persistence_mode        = "RDB"
  rdb_snapshot_period     = "SIX_HOURS"
  rdb_snapshot_start_time = "04:00"

  redis_configs = {
    "maxmemory-policy" = "allkeys-lru"
  }
}

output "redis_host" {
  value = module.my_redis.host
}

output "redis_port" {
  value = module.my_redis.port
}
