#########################################################
# Project / Basic settings
#########################################################

variable "project_id" {
  type        = string
  description = "The ID of the GCP project in which to create the Redis instance."
}

variable "region" {
  type        = string
  description = "The GCP region for the Redis instance (e.g., us-central1)."
}

variable "name" {
  type        = string
  description = "A unique name for the Redis instance."
}

variable "display_name" {
  type        = string
  description = "An optional display name for the Redis instance."
  default     = ""
}

variable "labels" {
  type        = map(string)
  description = "A set of key/value label pairs to assign to the Redis instance."
  default     = {}
}

#########################################################
# Redis core configuration
#########################################################

variable "tier" {
  type        = string
  description = "Service tier: BASIC or STANDARD_HA."
  default     = "BASIC"
  validation {
    condition     = contains(["BASIC", "STANDARD_HA"], var.tier)
    error_message = "tier must be BASIC or STANDARD_HA."
  }
}

variable "memory_size_gb" {
  type        = number
  description = "Memory size in GB for the Redis instance."
  default     = 1
  validation {
    condition     = var.memory_size_gb > 0
    error_message = "memory_size_gb must be > 0."
  }
}

variable "redis_version" {
  type        = string
  description = <<EOT
Version of Redis supported by Cloud Memorystore:
- REDIS_3_2
- REDIS_4_0
- REDIS_5_0
- REDIS_6_X
EOT
  default     = "REDIS_6_X"
  validation {
    condition = contains(["REDIS_3_2", "REDIS_4_0", "REDIS_5_0", "REDIS_6_X"], var.redis_version)
    error_message = "redis_version must be one of REDIS_3_2, REDIS_4_0, REDIS_5_0, REDIS_6_X."
  }
}

variable "redis_configs" {
  type        = map(string)
  description = <<EOT
Additional Redis configuration parameters, e.g.:
{
  "maxmemory-policy"       = "allkeys-lru"
  "notify-keyspace-events" = "KEA"
}
Refer to GCP docs for the full list of supported configs.
EOT
  default     = {}
}

#########################################################
# Networking
#########################################################

variable "authorized_network" {
  type        = string
  description = <<EOT
The VPC network in which to create the Redis instance.
Full resource path (e.g. projects/<proj>/global/networks/<network>)
or just the network name if using a recent provider.
Set to null to use the default network (not recommended for prod).
EOT
  default = null
}

variable "reserved_ip_range" {
  type        = string
  description = <<EOT
A CIDR range (e.g., 10.0.0.0/29) for the Redis instance. If null, GCP
will automatically choose a range.
EOT
  default = null
}

variable "connect_mode" {
  type        = string
  description = "Connection mode: DIRECT_PEERING or PRIVATE_SERVICE_ACCESS."
  default     = "DIRECT_PEERING"
  validation {
    condition     = contains(["DIRECT_PEERING", "PRIVATE_SERVICE_ACCESS"], var.connect_mode)
    error_message = "connect_mode must be DIRECT_PEERING or PRIVATE_SERVICE_ACCESS."
  }
}

variable "transit_encryption_mode" {
  type        = string
  description = "Transit encryption mode: DISABLED or SERVER_AUTHENTICATION (TLS)."
  default     = "DISABLED"
  validation {
    condition     = contains(["DISABLED", "SERVER_AUTHENTICATION"], var.transit_encryption_mode)
    error_message = "transit_encryption_mode must be DISABLED or SERVER_AUTHENTICATION."
  }
}

variable "auth_enabled" {
  type        = bool
  description = "Whether to enable Redis AUTH (password) - requires Redis >= 5.0."
  default     = false
}

#########################################################
# Firewall (like a security group)
#########################################################

variable "create_firewall" {
  type        = bool
  description = "If true, creates a firewall rule to allow traffic on port 6379."
  default     = false
}

variable "firewall_name" {
  type        = string
  description = "Name of the firewall rule if create_firewall = true."
  default     = "redis-firewall-rule"
}

variable "firewall_source_ranges" {
  type        = list(string)
  description = "CIDR source ranges allowed to connect to Redis on port 6379."
  default     = ["10.0.0.0/8"]
}

#########################################################
# Read replicas (STANDARD_HA)
#########################################################

variable "read_replicas_mode" {
  type        = string
  description = "READ_REPLICAS_DISABLED or READ_REPLICAS_ENABLED (STANDARD_HA only)."
  default     = "READ_REPLICAS_DISABLED"
  validation {
    condition     = contains(["READ_REPLICAS_DISABLED", "READ_REPLICAS_ENABLED"], var.read_replicas_mode)
    error_message = "read_replicas_mode must be READ_REPLICAS_DISABLED or READ_REPLICAS_ENABLED."
  }
}

variable "replica_count" {
  type        = number
  description = "Number of read replicas (when read_replicas_mode=READ_REPLICAS_ENABLED)."
  default     = 1
  validation {
    condition     = var.replica_count >= 1
    error_message = "replica_count must be >= 1."
  }
}

#########################################################
# Maintenance policy
#########################################################

variable "maintenance_day" {
  type        = string
  description = <<EOT
Day of the week for maintenance:
- MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY, SUNDAY
Set to null if you don't want to define a specific window.
EOT
  default = null
  validation {
    condition = var.maintenance_day == null
             || contains(
                  ["MONDAY","TUESDAY","WEDNESDAY","THURSDAY","FRIDAY","SATURDAY","SUNDAY"],
                  var.maintenance_day
                )
    error_message = "maintenance_day must be MONDAY..SUNDAY or null."
  }
}

variable "maintenance_start_hour" {
  type        = number
  description = "Hour (0-23) for the maintenance window start time (UTC)."
  default     = 3
  validation {
    condition     = var.maintenance_start_hour >= 0 && var.maintenance_start_hour <= 23
    error_message = "maintenance_start_hour must be between 0 and 23."
  }
}

variable "maintenance_start_minute" {
  type        = number
  description = "Minute (0-59) for the maintenance window start time (UTC)."
  default     = 0
  validation {
    condition     = var.maintenance_start_minute >= 0 && var.maintenance_start_minute <= 59
    error_message = "maintenance_start_minute must be between 0 and 59."
  }
}

#########################################################
# Persistence (RDB Snapshots)
#########################################################

variable "persistence_mode" {
  type        = string
  description = "Persistence mode: DISABLED or RDB."
  default     = "DISABLED"
  validation {
    condition     = contains(["DISABLED", "RDB"], var.persistence_mode)
    error_message = "persistence_mode must be DISABLED or RDB."
  }
}

variable "rdb_snapshot_period" {
  type        = string
  description = <<EOT
RDB snapshot period:
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
    error_message = "rdb_snapshot_period must be ONE_HOUR, SIX_HOURS, TWELVE_HOURS, TWENTY_FOUR_HOURS, or MANUAL."
  }
}

#########################################################
# CMEK (Customer Managed Encryption Key)
#########################################################

variable "kms_key_name" {
  type        = string
  description = <<EOT
Fully qualified KMS key name, e.g.:
projects/<project>/locations/<location>/keyRings/<ring>/cryptoKeys/<key>
If null, uses Google-managed encryption (DEK).
EOT
  default = null
}
