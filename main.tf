resource "google_redis_instance" "this" {
  name                       = var.name
  project                    = var.project_id
  region                     = var.region
  display_name               = var.display_name
  labels                     = var.labels

  tier                       = var.tier
  memory_size_gb             = var.memory_size_gb
  redis_version              = var.redis_version
  redis_configs              = var.redis_configs

  authorized_network         = var.authorized_network
  reserved_ip_range          = var.reserved_ip_range
  connect_mode               = var.connect_mode
  transit_encryption_mode    = var.transit_encryption_mode
  auth_enabled               = var.auth_enabled

  read_replicas_mode         = var.read_replicas_mode
  replica_count              = var.replica_count

  ############################
  # Maintenance Policy block
  ############################
  dynamic "maintenance_policy" {
    for_each = (
      var.maintenance_day != null && var.maintenance_start_time != null
    ) ? [1] : []
    
    content {
      # On peut définir plusieurs weekly_maintenance_window
      # Ici, on ne crée qu'une seule fenêtre si l'utilisateur renseigne un jour et une heure
      weekly_maintenance_window {
        day        = var.maintenance_day
        start_time = var.maintenance_start_time
      }
    }
  }

  ############################
  # Persistence Config block
  ############################
  dynamic "persistence_config" {
    for_each = var.persistence_mode == "RDB" ? [1] : []
    content {
      persistence_mode        = var.persistence_mode
      rdb_snapshot_period     = var.rdb_snapshot_period
      rdb_snapshot_start_time = var.rdb_snapshot_start_time
    }
  }
}
