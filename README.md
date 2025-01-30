# Terraform GCP Redis (Cloud Memorystore) Module Documentation

## Table of Contents
1. [Introduction](#introduction)  
2. [Objectives & Features](#objectives--features)  
3. [Architecture & Key Concepts](#architecture--key-concepts)  
4. [Prerequisites & Setup](#prerequisites--setup)  
5. [Variables & Configuration](#variables--configuration)  
6. [Maintenance, Persistence, Security, & Encryption](#maintenance-persistence-security--encryption)  
7. [Example Usage](#example-usage)  
8. [Best Practices & Recommendations](#best-practices--recommendations)  
9. [Troubleshooting](#troubleshooting)  
10. [References](#references)

---

## Introduction

This Terraform module automates the deployment and configuration of **Cloud Memorystore for Redis** on **Google Cloud Platform (GCP)**. It manages:

- The creation and configuration of the Redis instance (BASIC or STANDARD_HA tier).  
- Enabling persistence (RDB Snapshots) if needed.  
- Maintenance window configuration.  
- Network access (VPC, optional firewall rule).  
- Optionally, a **KMS key** for at-rest encryption (CMEK).

By using this module, you can **consistently**, **scalably**, and **securely** provision Redis on GCP.

---

## Objectives & Features

- **Create a Redis Instance**  
  - Choose between BASIC (single instance) or STANDARD_HA (high availability).  
  - Specify memory size, Redis version, and additional Redis configs.

- **Network & Connectivity**  
  - Optionally specify a custom VPC (`authorized_network`).  
  - Choose connect mode: `DIRECT_PEERING` or `PRIVATE_SERVICE_ACCESS`.  
  - Optionally configure a firewall rule to allow Redis traffic on port 6379.

- **Maintenance & Patching**  
  - Define a weekly maintenance window (day + hour/minute).

- **Persistence (RDB)**  
  - Disabled by default or enabled with periodic snapshots (1 hour, 6 hours, etc.).  
  - GCP manages snapshots automatically.

- **Security**  
  - **Encryption in transit**: `SERVER_AUTHENTICATION` (TLS) or `DISABLED`.  
  - **Encryption at rest**:
    - By default, Google-managed encryption (DEK).  
    - Optionally, CMEK (Customer-Managed Encryption Key) through Cloud KMS.

- **Read Replicas** (for STANDARD_HA)  
  - Enable read replicas via `read_replicas_mode` and `replica_count`.

---

## Architecture & Key Concepts

### 3.1 General Architecture

1. **Terraform Module**  
   - Deploys a `google_redis_instance` resource on GCP.  
   - Optionally creates a `google_compute_firewall` resource to allow internal traffic on port 6379.

2. **VPC**  
   - The Redis instance lives on a private IP within the specified VPC.  
   - No public IP access: any connections must happen from the same or peered VPC.

3. **Maintenance Policy**  
   - GCP automatically applies updates/patches within the defined maintenance window.

4. **RDB Persistence**  
   - Snapshots are stored on Google infrastructure.  
   - Configurable frequency (1 hour, 6 hours, etc.).

### 3.2 Key Concepts

- **BASIC vs STANDARD_HA**  
  - BASIC: single node, no high availability.  
  - STANDARD_HA: automatic failover with higher resiliency.

- **Encryption in Transit**  
  - `SERVER_AUTHENTICATION` for TLS, `DISABLED` otherwise.

- **Encryption at Rest**  
  - **Default**: Google-managed encryption key (DEK).  
  - **CMEK**: user-managed key via Cloud KMS (rotate/revoke at your control).

- **Firewall**  
  - Controlled via `google_compute_firewall`.  
  - Restricts inbound connections to specific source IP ranges.

---

## Prerequisites & Setup

1. **GCP Accounts & Roles**  
   - You need an active GCP project.  
   - IAM roles such as `roles/redis.admin`, `roles/compute.networkAdmin`, and `roles/compute.securityAdmin` may be required.

2. **Terraform**  
   - Use Terraform **1.x** (preferably 1.3+).  
   - A recent **Google provider** version.

3. **Enable GCP APIs**  
   - `redis.googleapis.com` for Cloud Memorystore.  
   - `compute.googleapis.com` for firewall (if needed).

4. **Service Account (optional)**  
   - If using a service account JSON key, specify `credentials = file("path/to/key.json")`.  
   - Ensure it has permissions to manage Redis, VPC, etc.

5. **For CMEK** (optional)  
   - Create a KMS key in the required region.  
   - Grant `roles/cloudkms.cryptoKeyEncrypterDecrypter` to the Cloud Memorystore service account.

---

## Variables & Configuration

Below is an overview of main variables (see the module’s `variables.tf` for full details):

| Variable                   | Type             | Default             | Description                                                                                                                                         |
|---------------------------|------------------|---------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|
| `project_id`              | `string`         | - (required)        | GCP project ID                                                                                                                                      |
| `region`                  | `string`         | - (required)        | GCP region (e.g., `us-central1`)                                                                                                                    |
| `name`                    | `string`         | - (required)        | Unique Redis instance name                                                                                                                          |
| `tier`                    | `string`         | `"BASIC"`           | `BASIC` or `STANDARD_HA`                                                                                                                            |
| `memory_size_gb`          | `number`         | `1`                 | Memory size in GB                                                                                                                                   |
| `redis_version`           | `string`         | `"REDIS_6_X"`       | Redis version (e.g., `REDIS_5_0`)                                                                                                                   |
| `redis_configs`           | `map(string)`    | `{}`                | Additional Redis configs (key-value pairs)                                                                                                          |
| `authorized_network`      | `string \| null` | `null`              | VPC network (e.g., `projects/<proj>/global/networks/<name>`)                                                                                       |
| `reserved_ip_range`       | `string \| null` | `null`              | Reserved IP range (CIDR), e.g., `10.0.0.0/29`                                                                                                        |
| `connect_mode`            | `string`         | `"DIRECT_PEERING"`  | `DIRECT_PEERING` or `PRIVATE_SERVICE_ACCESS`                                                                                                        |
| `transit_encryption_mode` | `string`         | `"DISABLED"`        | `SERVER_AUTHENTICATION` (TLS) or `DISABLED`                                                                                                         |
| `auth_enabled`            | `bool`           | `false`             | Enable Redis AUTH (for Redis >=5.0)                                                                                                                 |
| `read_replicas_mode`      | `string`         | `"READ_REPLICAS_DISABLED"` | Enable read replicas if set to `READ_REPLICAS_ENABLED` (only in STANDARD_HA)                                                                  |
| `replica_count`           | `number`         | `1`                 | Number of read replicas                                                                                                                             |
| `maintenance_day`         | `string \| null` | `null`              | Maintenance day (e.g., `TUESDAY`)                                                                                                                   |
| `maintenance_start_hour`  | `number`         | `3`                 | Hour (0–23)                                                                                                                                         |
| `maintenance_start_minute`| `number`         | `0`                 | Minute (0–59)                                                                                                                                       |
| `persistence_mode`        | `string`         | `"DISABLED"`        | `DISABLED` or `RDB`                                                                                                                                 |
| `rdb_snapshot_period`     | `string`         | `"SIX_HOURS"`       | `ONE_HOUR`, `SIX_HOURS`, `TWELVE_HOURS`, `TWENTY_FOUR_HOURS`, or `MANUAL`                                                                           |
| `kms_key_name`            | `string \| null` | `null`              | Full KMS key name (for CMEK) or `null` for default GCP encryption                                                                                   |
| `create_firewall`         | `bool`           | `false`             | Whether to create a firewall rule for Redis port 6379                                                                                               |
| `firewall_name`           | `string`         | `"redis-firewall-rule"` | Firewall rule name                                                                                                                             |
| `firewall_source_ranges`  | `list(string)`   | `["10.0.0.0/8"]`    | Source IP ranges allowed on port 6379                                                                                                               |

---

## Maintenance, Persistence, Security, & Encryption

### Maintenance Policy

- **maintenance_day**: A weekly day like `MONDAY`, `TUESDAY`, etc.  
- **maintenance_start_hour** / **maintenance_start_minute**: Controls the UTC start time of updates.  
- If `maintenance_day` is `null`, no custom window is set and GCP chooses automatically.

### Persistence (RDB Snapshots)

- **persistence_mode**: `DISABLED` or `RDB`.  
- **rdb_snapshot_period**: frequency for RDB snapshots (`ONE_HOUR`, `SIX_HOURS`, etc.).  
- Snapshots are stored on Google’s infrastructure with built-in encryption.

### Security / Encryption

1. **Encryption in Transit**  
   - `DISABLED`: no TLS.  
   - `SERVER_AUTHENTICATION`: TLS enabled; clients must support TLS.

2. **Encryption at Rest**  
   - **Default**: Google-managed data encryption key (DEK).  
   - **CMEK**: Provide a user-managed KMS key name (`kms_key_name`). You must handle IAM and key rotation.

### Firewall

- If `create_firewall` is `true`, a `google_compute_firewall` resource is created to allow TCP port 6379 from specified `firewall_source_ranges`.  
- This is an **internal** firewall rule, as Redis is private.

---

## Example Usage

### File Structure

./ ├── main.tf ├── variables.tf ├── outputs.tf └── ...


> If you place these files in `modules/gcp-redis`, you can reference it as `source = "./modules/gcp-redis"`.

### Terraform Configuration Example

```hcl
provider "google" {
  project = "my-gcp-project"
  region  = "us-central1"
  # credentials = file("keys/serviceaccount.json")  # if needed
}

module "redis_instance" {
  source = "./modules/gcp-redis"

  project_id = "my-gcp-project"
  region     = "us-central1"
  name       = "my-redis-production"

  tier            = "STANDARD_HA"
  memory_size_gb  = 2
  redis_version   = "REDIS_6_X"
  auth_enabled    = true

  authorized_network      = "projects/my-gcp-project/global/networks/my-vpc"
  connect_mode            = "DIRECT_PEERING"
  transit_encryption_mode = "SERVER_AUTHENTICATION"

  maintenance_day         = "WEDNESDAY"
  maintenance_start_hour  = 2
  maintenance_start_minute= 30

  persistence_mode    = "RDB"
  rdb_snapshot_period = "SIX_HOURS"

  # Optional firewall
  create_firewall        = true
  firewall_name          = "redis-6379"
  firewall_source_ranges = ["10.128.0.0/16"]

  # Optional CMEK
  # kms_key_name = "projects/my-gcp-project/locations/us/keyRings/my-ring/cryptoKeys/my-redis-key"

  redis_configs = {
    "maxmemory-policy" = "allkeys-lru"
  }
}

output "redis_host" {
  value = module.redis_instance.redis_host
}


Best Practices & Recommendations

    Credential Management
        Avoid committing service account JSON keys to public repos.
        Use a secure remote backend for terraform.tfstate.

    Versioning
        Pin your Google provider version in required_providers.
        Keep Terraform updated, and check GCP docs for changes.

    High Availability
        Use STANDARD_HA in production for better resilience.
        Ensure your chosen region supports it.

    Maintenance Window
        Schedule it outside critical production hours.
        Track GCP notices for maintenance events.

    Persistence
        Use RDB if you need data backups; otherwise DISABLED for ephemeral caching.
        rdb_snapshot_period does not let you pick an exact daily time; GCP schedules the snapshots internally.

    CMEK
        If you use a custom KMS key, ensure you’ve granted cloudkms.cryptoKeyEncrypterDecrypter to the Memorystore service account.
        Handle key rotation and revocation policies as needed.

    Separate Environments
        Use Terraform workspaces (prod, staging, dev) or separate GCP projects.
        Avoid mixing multiple environments in the same Terraform state.

Troubleshooting
Issue	Possible Cause	Solution
unsupported argument rdb_snapshot_interval	That parameter doesn’t exist in the official provider.	Use rdb_snapshot_period instead.
unsupported block "customer_managed_key"	Your provider version may be old or it might require google-beta.	Upgrade the provider or switch to the beta provider.
Can’t set start_time = "03:00" for maintenance	GCP requires start_time { hours, minutes } blocks in weekly_maintenance_window.	Use maintenance_day, maintenance_start_hour, maintenance_start_minute.
illegal rdb_snapshot_start_time error	Often that field is read-only or requires RFC3339.	Remove or ignore that field; rely on rdb_snapshot_period.
Unable to connect to Redis on port 6379	No firewall rule or incorrect firewall_source_ranges.	Check create_firewall and the source IP ranges.
CMEK authorization error	Missing KMS IAM role for the service account.	Grant cloudkms.cryptoKeyEncrypterDecrypter to the Cloud Redis SA.
References

    Terraform Google Provider
    https://registry.terraform.io/providers/hashicorp/google/latest/docs

    google_redis_instance Resource
    https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/redis_instance

    Cloud Memorystore for Redis
    https://cloud.google.com/memorystore/docs/redis

    KMS (CMEK) Docs
    https://cloud.google.com/kms/docs

    Google Compute Firewall
    https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall

Conclusion

This module provides an automated and secure way to deploy Redis (Cloud Memorystore) on GCP. It covers networking, maintenance policies, data persistence, and optional KMS-based encryption for data at rest. By following the best practices listed here, you will achieve a robust, scalable, and maintainable Redis infrastructure on Google Cloud.