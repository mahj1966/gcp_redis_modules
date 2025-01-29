provider "google" {
  project = "votre_projet_id"
  region  = "us-central1"
  # credentials = file("chemin/vers/ma/clé.json")  # si vous utilisez un compte de service
}

module "redis_instance" {
  source = "./modules/redis"

  project_id    = "votre_projet_id"
  region        = "us-central1"
  name          = "my-redis-instance"
  display_name  = "Redis Production"

  labels = {
    environment = "production"
    team        = "backend"
  }

  tier            = "STANDARD_HA"
  memory_size_gb  = 2
  redis_version   = "REDIS_6_X"

  redis_configs = {
    "maxmemory-policy"       = "allkeys-lru"
    "notify-keyspace-events" = "KEA"
  }

  authorized_network      = "projects/votre_projet_id/global/networks/my-vpc"
  reserved_ip_range       = "10.10.0.0/29"
  connect_mode            = "DIRECT_PEERING"
  transit_encryption_mode = "SERVER_AUTHENTICATION"
  auth_enabled            = true

  read_replicas_mode = "READ_REPLICAS_ENABLED"
  replica_count      = 2

  maintenance_day        = "TUESDAY"
  maintenance_start_time = "03:00"

  persistence_mode        = "RDB"
  rdb_snapshot_period     = "HOURS"
  rdb_snapshot_interval   = 6
}

output "redis_host" {
  value = module.redis_instance.host
}

output "redis_port" {
  value = module.redis_instance.port
}
