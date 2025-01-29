provider "google" {
  project = "my-gcp-project"
  region  = "us-central1"
  # credentials = file("path/to/service-account.json")
}

module "redis_instance" {
  source = "./modules/redis"
  
  project_id    = "my-gcp-project"
  region        = "us-central1"
  name          = "my-redis-instance"
  display_name  = "My Redis in Production"

  tier            = "STANDARD_HA"
  memory_size_gb  = 2
  redis_version   = "REDIS_6_X"

  authorized_network      = "projects/my-gcp-project/global/networks/my-custom-network"
  connect_mode            = "DIRECT_PEERING"
  transit_encryption_mode = "SERVER_AUTHENTICATION"
  auth_enabled            = true

  read_replicas_mode = "READ_REPLICAS_ENABLED"
  replica_count       = 2

  maintenance_day        = "TUESDAY"
  maintenance_start_time = "03:00"

  persistence_mode        = "RDB"
  rdb_snapshot_period     = "SIX_HOURS"
  rdb_snapshot_start_time = "04:00"

  redis_configs = {
    "maxmemory-policy" = "allkeys-lru"
  }
}

output "redis_host" {
  value = module.redis_instance.redis_host
}

output "redis_port" {
  value = module.redis_instance.redis_port
}
