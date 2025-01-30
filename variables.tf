########################################
# Provider / Project Configuration
########################################

variable "project_id" {
  type        = string
  description = "ID du projet GCP où créer l'instance Redis."
}

variable "region" {
  type        = string
  description = "Région GCP pour l'instance Redis (ex: us-central1)."
}

variable "name" {
  type        = string
  description = "Nom unique de l'instance Redis."
}

variable "display_name" {
  type        = string
  description = "Nom d'affichage de l'instance (purement descriptif)."
  default     = ""
}

variable "labels" {
  type        = map(string)
  description = "Labels à appliquer à l'instance Redis."
  default     = {}
}

########################################
# Redis Instance Configuration
########################################

variable "tier" {
  type        = string
  description = "Niveau de service: 'BASIC' ou 'STANDARD_HA'."
  default     = "BASIC"
  validation {
    condition     = contains(["BASIC", "STANDARD_HA"], var.tier)
    error_message = "tier doit être 'BASIC' ou 'STANDARD_HA'."
  }
}

variable "memory_size_gb" {
  type        = number
  description = "Taille de la mémoire Redis, en Go."
  default     = 1
  validation {
    condition     = var.memory_size_gb > 0
    error_message = "memory_size_gb doit être > 0."
  }
}

variable "redis_version" {
  type        = string
  description = <<EOT
Version Redis supportée par Cloud Memorystore:
 - REDIS_3_2
 - REDIS_4_0
 - REDIS_5_0
 - REDIS_6_X
EOT
  default     = "REDIS_6_X"
  validation {
    condition = contains(["REDIS_3_2", "REDIS_4_0", "REDIS_5_0", "REDIS_6_X"], var.redis_version)
    error_message = "redis_version doit être REDIS_3_2, REDIS_4_0, REDIS_5_0 ou REDIS_6_X."
  }
}

variable "redis_configs" {
  type        = map(string)
  description = <<EOT
Configuration Redis supplémentaire. Exemple:
{
  "maxmemory-policy"       = "allkeys-lru"
  "notify-keyspace-events" = "KEA"
}
EOT
  default     = {}
}

########################################
# Network / Firewall
########################################

variable "authorized_network" {
  type        = string
  description = <<EOT
Réseau VPC où déployer l'instance Redis.
Ex: projects/<project_id>/global/networks/<network_name>
Laisser null pour le réseau par défaut.
EOT
  default = null
}

variable "reserved_ip_range" {
  type        = string
  description = <<EOT
Plage IP (CIDR) réservée pour l'instance Redis.
Ex: 10.0.0.0/29
Laisser null pour que GCP en assigne automatiquement.
EOT
  default = null
}

variable "connect_mode" {
  type        = string
  description = "Mode de connexion : 'DIRECT_PEERING' ou 'PRIVATE_SERVICE_ACCESS'."
  default     = "DIRECT_PEERING"
  validation {
    condition     = contains(["DIRECT_PEERING", "PRIVATE_SERVICE_ACCESS"], var.connect_mode)
    error_message = "connect_mode doit être 'DIRECT_PEERING' ou 'PRIVATE_SERVICE_ACCESS'."
  }
}

variable "transit_encryption_mode" {
  type        = string
  description = "Mode de chiffrement en transit: 'SERVER_AUTHENTICATION' ou 'DISABLED'."
  default     = "DISABLED"
  validation {
    condition     = contains(["SERVER_AUTHENTICATION", "DISABLED"], var.transit_encryption_mode)
    error_message = "transit_encryption_mode doit être 'SERVER_AUTHENTICATION' ou 'DISABLED'."
  }
}

variable "auth_enabled" {
  type        = bool
  description = "Activer ou non l'auth Redis (AUTH)."
  default     = false
}

# Firewall-like config
variable "create_firewall" {
  type        = bool
  description = "Créer ou non un firewall rule pour autoriser le trafic sur le port Redis (6379)."
  default     = false
}

variable "firewall_name" {
  type        = string
  description = "Nom de la règle Firewall (si create_firewall = true)."
  default     = "redis-firewall-rule"
}

variable "firewall_source_ranges" {
  type        = list(string)
  description = "Plages CIDR autorisées à accéder à Redis (port 6379) au sein du réseau."
  default     = ["10.0.0.0/8"]
}

########################################
# Replicas (STANDARD_HA)
########################################

variable "read_replicas_mode" {
  type        = string
  description = "Activer ou non les réplicas en lecture: 'READ_REPLICAS_DISABLED' ou 'READ_REPLICAS_ENABLED'."
  default     = "READ_REPLICAS_DISABLED"
  validation {
    condition     = contains(["READ_REPLICAS_DISABLED", "READ_REPLICAS_ENABLED"], var.read_replicas_mode)
    error_message = "read_replicas_mode doit être 'READ_REPLICAS_DISABLED' ou 'READ_REPLICAS_ENABLED'."
  }
}

variable "replica_count" {
  type        = number
  description = "Nombre de réplicas en lecture (si read_replicas_mode=READ_REPLICAS_ENABLED)."
  default     = 1
  validation {
    condition     = var.replica_count >= 1
    error_message = "replica_count doit être >= 1."
  }
}

########################################
# Maintenance Policy
# GCP requires weekly_maintenance_window with day + start_time block
########################################

variable "maintenance_day" {
  type        = string
  description = <<EOT
Jour de maintenance planifiée:
 'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY',
 'FRIDAY', 'SATURDAY', 'SUNDAY'
ou null pour ne pas configurer.
EOT
  default = null
  validation {
    condition = var.maintenance_day == null
             || contains(
                  ["MONDAY","TUESDAY","WEDNESDAY","THURSDAY","FRIDAY","SATURDAY","SUNDAY"],
                  var.maintenance_day
                )
    error_message = "maintenance_day doit être MONDAY..SUNDAY ou null."
  }
}

variable "maintenance_start_hour" {
  type        = number
  description = "Heure de début de maintenance (0 à 23)."
  default     = 3
  validation {
    condition     = var.maintenance_start_hour >= 0 && var.maintenance_start_hour <= 23
    error_message = "maintenance_start_hour doit être entre 0 et 23."
  }
}

variable "maintenance_start_minute" {
  type        = number
  description = "Minute de début de maintenance (0 à 59)."
  default     = 0
  validation {
    condition     = var.maintenance_start_minute >= 0 && var.maintenance_start_minute <= 59
    error_message = "maintenance_start_minute doit être entre 0 et 59."
  }
}

########################################
# Persistence (RDB Snapshots)
########################################

variable "persistence_mode" {
  type        = string
  description = <<EOT
Mode de persistance:
 - DISABLED : aucune persistance
 - RDB      : snapshots sur disque
EOT
  default = "DISABLED"
  validation {
    condition     = contains(["DISABLED", "RDB"], var.persistence_mode)
    error_message = "persistence_mode doit être 'DISABLED' ou 'RDB'."
  }
}

variable "rdb_snapshot_period" {
  type        = string
  description = <<EOT
Périodicité des snapshots RDB:
 - ONE_HOUR
 - SIX_HOURS
 - TWELVE_HOURS
 - TWENTY_FOUR_HOURS
 - MANUAL
EOT
  default = "SIX_HOURS"
  validation {
    condition = contains(
      ["ONE_HOUR", "SIX_HOURS", "TWELVE_HOURS", "TWENTY_FOUR_HOURS", "MANUAL"],
      var.rdb_snapshot_period
    )
    error_message = "rdb_snapshot_period doit être: ONE_HOUR, SIX_HOURS, TWELVE_HOURS, TWENTY_FOUR_HOURS, ou MANUAL."
  }
}

########################################
# CMEK (Customer Managed Encryption Key)
########################################

variable "kms_key_name" {
  type        = string
  description = <<EOT
Nom complet de la clé KMS pour la gestion du chiffrement à
rest (ex: projects/<project_id>/locations/<location>/keyRings/<ring>/cryptoKeys/<key>).
Laisser null pour utiliser l'encryption par défaut GCP.
EOT
  default = null
}
