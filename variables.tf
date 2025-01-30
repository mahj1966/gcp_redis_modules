########################################
# Project / Basic Settings
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
# Core Redis Configuration
########################################

variable "tier" {
  type        = string
  description = "Niveau de service de l'instance: 'BASIC' ou 'STANDARD_HA'."
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
Reportez-vous à la doc GCP pour la liste des clés supportées.
EOT
  default     = {}
}

########################################
# Networking
########################################

variable "authorized_network" {
  type        = string
  description = <<EOT
Réseau VPC où déployer l'instance Redis.  
Ex: projects/<project_id>/global/networks/<network_name>
Laisser null pour utiliser le réseau par défaut.
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
  description = <<EOT
Activer ou non l'authentification Redis (AUTH).
Uniquement dispo pour Redis >= 5.0.
EOT
  default = false
}

########################################
# Replicas (for STANDARD_HA)
########################################

variable "read_replicas_mode" {
  type        = string
  description = "Activer les réplicas en lecture: 'READ_REPLICAS_DISABLED' ou 'READ_REPLICAS_ENABLED'."
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
########################################
# GCP requires a nested `start_time { hours = X, minutes = Y }` block 
# in weekly_maintenance_window.
########################################

variable "maintenance_day" {
  type        = string
  description = <<EOT
Jour de maintenance planifiée.
- L'un de: MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY
- null pour ne pas configurer de fenêtre de maintenance.
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
  description = "Heure de début de maintenance (0-23)."
  default     = 3

  validation {
    condition     = var.maintenance_start_hour >= 0 && var.maintenance_start_hour <= 23
    error_message = "maintenance_start_hour doit être entre 0 et 23."
  }
}

variable "maintenance_start_minute" {
  type        = number
  description = "Minute de début de maintenance (0-59)."
  default     = 0

  validation {
    condition     = var.maintenance_start_minute >= 0 && var.maintenance_start_minute <= 59
    error_message = "maintenance_start_minute doit être entre 0 et 59."
  }
}

########################################
# Persistence (RDB snapshots)
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
    error_message = "rdb_snapshot_period doit être ONE_HOUR, SIX_HOURS, TWELVE_HOURS, TWENTY_FOUR_HOURS ou MANUAL."
  }
}

variable "rdb_snapshot_start_time" {
  type        = string
  description = "Heure de début du snapshot RDB, au format HH:MM (UTC). Ex: 03:00 (ou null)."
  default     = null

  validation {
    condition = var.rdb_snapshot_start_time == null
             || can(
               regex("^([0-1]\\d|2[0-3]):([0-5]\\d)$", var.rdb_snapshot_start_time)
             )
    error_message = "rdb_snapshot_start_time doit être null ou au format HH:MM (00:00 à 23:59)."
  }
}
