
##############################
# Variables principales
##############################

variable "project_id" {
  type        = string
  description = "ID du projet GCP dans lequel créer l'instance Redis."
}

variable "region" {
  type        = string
  description = "Région GCP où déployer l'instance Redis (ex: us-central1)."
}

variable "name" {
  type        = string
  description = "Nom unique de l'instance Redis."
}

variable "display_name" {
  type        = string
  description = "Nom d'affichage de l'instance (champ purement descriptif dans GCP)."
  default     = ""
}

variable "labels" {
  type        = map(string)
  description = "Labels à appliquer à l'instance Redis."
  default     = {}
}

##############################
# Configuration Redis
##############################

variable "tier" {
  type        = string
  description = "Le service tier de l'instance. Peut être BASIC ou STANDARD_HA."
  default     = "BASIC"
  validation {
    condition     = contains(["BASIC", "STANDARD_HA"], var.tier)
    error_message = "tier doit être soit 'BASIC' soit 'STANDARD_HA'."
  }
}

variable "memory_size_gb" {
  type        = number
  description = "Taille de la mémoire Redis en Go."
  default     = 1
  validation {
    condition     = var.memory_size_gb > 0
    error_message = "memory_size_gb doit être un nombre entier > 0."
  }
}

variable "redis_version" {
  type        = string
  description = <<EOT
Version de Redis, ex:
- REDIS_3_2
- REDIS_4_0
- REDIS_5_0
- REDIS_6_X
EOT
  default     = "REDIS_6_X"
  validation {
    condition = contains(
      ["REDIS_3_2", "REDIS_4_0", "REDIS_5_0", "REDIS_6_X"],
      var.redis_version
    )
    error_message = "redis_version doit être parmi REDIS_3_2, REDIS_4_0, REDIS_5_0, REDIS_6_X."
  }
}

variable "redis_configs" {
  type        = map(string)
  description = <<EOT
Ensemble de clés/valeurs pour configurer Redis.
Ex : {
  "maxmemory-policy" = "allkeys-lru"
  "notify-keyspace-events" = "KEA"
}
Voir la doc GCP pour la liste complète des options supportées.
EOT
  default     = {}
}

##############################
# Réseau et connectivité
##############################

variable "authorized_network" {
  type        = string
  description = <<EOT
Réseau VPC sur lequel déployer l'instance Redis.
Peut être l'URL complète (ex : projects/<project_id>/global/networks/<network_name>)
ou simplement le nom du réseau (selon la version du provider).
EOT
  default = null
}

variable "reserved_ip_range" {
  type        = string
  description = <<EOT
Plage IP réservée pour l'instance Redis (CIDR).
Si non spécifié, GCP en attribue une automatiquement.
Ex: 10.0.0.0/29
EOT
  default = null
}

variable "connect_mode" {
  type        = string
  description = "Mode de connexion : DIRECT_PEERING ou PRIVATE_SERVICE_ACCESS."
  default     = "DIRECT_PEERING"
  validation {
    condition     = contains(["DIRECT_PEERING", "PRIVATE_SERVICE_ACCESS"], var.connect_mode)
    error_message = "connect_mode doit être 'DIRECT_PEERING' ou 'PRIVATE_SERVICE_ACCESS'."
  }
}

variable "transit_encryption_mode" {
  type        = string
  description = "Mode de chiffrement en transit : ENABLED (SERVER_AUTHENTICATION) ou DISABLED."
  default     = "DISABLED"
  validation {
    # Dans la doc GCP, la valeur attendue est "SERVER_AUTHENTICATION" ou "DISABLED".
    condition     = contains(["SERVER_AUTHENTICATION", "DISABLED"], var.transit_encryption_mode)
    error_message = "transit_encryption_mode doit être 'SERVER_AUTHENTICATION' ou 'DISABLED'."
  }
}

variable "auth_enabled" {
  type        = bool
  description = <<EOT
Activer l'authentification Redis AUTH. Permet de définir un mot de passe pour la connexion.
Disponible uniquement pour Redis 5.0 et plus.
EOT
  default = false
}

##############################
# Réplicas (STANDARD_HA)
##############################

variable "read_replicas_mode" {
  type        = string
  description = "Active ou non les réplicas en lecture : READ_REPLICAS_DISABLED ou READ_REPLICAS_ENABLED."
  default     = "READ_REPLICAS_DISABLED"
  validation {
    condition     = contains(["READ_REPLICAS_DISABLED", "READ_REPLICAS_ENABLED"], var.read_replicas_mode)
    error_message = "read_replicas_mode doit être 'READ_REPLICAS_DISABLED' ou 'READ_REPLICAS_ENABLED'."
  }
}

variable "replica_count" {
  type        = number
  description = "Nombre de réplicas en lecture (uniquement valable si read_replicas_mode = READ_REPLICAS_ENABLED)."
  default     = 1
  validation {
    condition     = var.replica_count >= 1
    error_message = "replica_count doit être >= 1."
  }
}

##############################
# Maintenance Policy
##############################
variable "maintenance_day" {
  type        = string
  description = <<EOT
Jour de maintenance planifié (MONDAY, TUESDAY, WEDNESDAY, THURSDAY,
FRIDAY, SATURDAY, SUNDAY). Si vous ne souhaitez pas configurer,
laissez à null.
EOT
  default = null
  validation {
    condition = var.maintenance_day == null ||
                contains(
                  ["MONDAY","TUESDAY","WEDNESDAY","THURSDAY","FRIDAY","SATURDAY","SUNDAY"],
                  var.maintenance_day
                )
    error_message = "maintenance_day doit être l'un des jours valides ou null."
  }
}

variable "maintenance_start_time" {
  type        = string
  description = <<EOT
Heure de début de la maintenance planifiée, au format HH:MM en UTC (ex: 03:00).
Si null, pas de configuration explicite.
EOT
  default = null
  validation {
    condition = var.maintenance_start_time == null ||
                can(regex("^[0-1][0-9]:[0-5][0-9]|2[0-3]:[0-5][0-9]$", var.maintenance_start_time))
    error_message = "maintenance_start_time doit être au format HH:MM (00:00 à 23:59) ou null."
  }
}

##############################
# Persistence
##############################

variable "persistence_mode" {
  type        = string
  description = <<EOT
Mode de persistance, ex: DISABLED ou RDB
- DISABLED : pas de persistance
- RDB      : snapshots en disque
EOT
  default     = "DISABLED"
  validation {
    condition     = contains(["DISABLED", "RDB"], var.persistence_mode)
    error_message = "persistence_mode doit être 'DISABLED' ou 'RDB'."
  }
}

variable "rdb_snapshot_period" {
  type        = string
  description = <<EOT
Périodicité des snapshots (SECONDS, MINUTES, HOURS, DAYS).
Uniquement si persistence_mode = RDB.
EOT
  default = null
  validation {
    condition = var.rdb_snapshot_period == null ||
                contains(["SECONDS","MINUTES","HOURS","DAYS"], var.rdb_snapshot_period)
    error_message = "rdb_snapshot_period doit être SECONDS, MINUTES, HOURS, DAYS ou null."
  }
}

variable "rdb_snapshot_interval" {
  type        = number
  description = "Intervalle (nombre) pour les snapshots selon le rdb_snapshot_period."
  default     = null
  validation {
    condition     = var.rdb_snapshot_interval == null || var.rdb_snapshot_interval > 0
    error_message = "rdb_snapshot_interval doit être > 0 ou null."
  }
}
