provider "google" {
  project = "my-project-id"
  region  = "us-central1"
  # credentials = file("path/to/service-account.json") # if needed
}

module "redis_instance" {
  source = "./modules/redis"

  project_id    = "my-project-id"
  region        = "us-central1"
  name          = "my-redis-prod"
  display_name  = "Production Redis"
  tier          = "STANDARD_HA"
  memory_size_gb = 2
  redis_version  = "REDIS_6_X"

  auth_enabled            = true
  connect_mode            = "DIRECT_PEERING"
  transit_encryption_mode = "SERVER_AUTHENTICATION"

  authorized_network = "projects/my-project-id/global/networks/custom-vpc"
  reserved_ip_range  = "10.10.1.0/29"

  maintenance_day         = "TUESDAY"
  maintenance_start_hour  = 2
  maintenance_start_minute= 15

  persistence_mode    = "RDB"
  rdb_snapshot_period = "SIX_HOURS"

  # Optional: create an internal firewall rule
  create_firewall        = true
  firewall_name          = "redis-6379-firewall"
  firewall_source_ranges = ["10.128.0.0/16"]

  # CMEK example:
  # kms_key_name = "projects/my-project-id/locations/us/keyRings/my-ring/cryptoKeys/my-redis-key"

  # Additional Redis config
  redis_configs = {
    "maxmemory-policy" = "allkeys-lru"
  }
}

output "redis_host" {
  value = module.redis_instance.host
}

output "redis_port" {
  value = module.redis_instance.port
}
