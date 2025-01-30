########################################
# Redis instance
########################################
resource "google_redis_instance" "this" {
  # Might require:
  # provider = google-beta
  # if you're using the beta feature for CMEK

  name            = var.name
  project         = var.project_id
  region          = var.region
  display_name    = var.display_name
  labels          = var.labels

  tier                   = var.tier
  memory_size_gb         = var.memory_size_gb
  redis_version          = var.redis_version
  redis_configs          = var.redis_configs
  authorized_network     = var.authorized_network
  reserved_ip_range      = var.reserved_ip_range
  connect_mode           = var.connect_mode
  transit_encryption_mode= var.transit_encryption_mode
  auth_enabled           = var.auth_enabled

  read_replicas_mode     = var.read_replicas_mode
  replica_count          = var.replica_count

  ############################
  # Maintenance Policy
  ############################
  dynamic "maintenance_policy" {
    for_each = var.maintenance_day != null ? [1] : []
    content {
      weekly_maintenance_window {
        day = var.maintenance_day

        start_time {
          hours   = var.maintenance_start_hour
          minutes = var.maintenance_start_minute
        }
      }
    }
  }

  ############################
  # Persistence (RDB Snapshots)
  ############################
  dynamic "persistence_config" {
    for_each = var.persistence_mode == "RDB" ? [1] : []
    content {
      persistence_mode    = var.persistence_mode
      rdb_snapshot_period = var.rdb_snapshot_period
      # rdb_snapshot_start_time is often read-only or not recommended
      # unless your provider version explicitly supports setting it in RFC3339.
    }
  }

  ############################
  # Encryption at Rest (CMEK)
  ############################
  dynamic "customer_managed_key" {
    for_each = var.kms_key_name == null ? [] : [var.kms_key_name]
    content {
      kms_key_name = customer_managed_key.value
    }
  }
}

########################################
# Firewall rule (like a security group)
########################################
resource "google_compute_firewall" "redis_firewall" {
  # This resource is only created if create_firewall = true
  count = var.create_firewall ? 1 : 0

  name    = var.firewall_name
  project = var.project_id
  network = var.authorized_network

  allow {
    protocol = "tcp"
    ports    = ["6379"]
  }

  source_ranges = var.firewall_source_ranges

  # Optionally label your firewall rule
  # labels = {
  #   "component" = "redis-firewall"
  # }
}
