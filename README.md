# gcp_redis_modules
Voici un exemple de documentation complète (à la fois technique et conceptuelle) pour votre module Terraform Cloud Memorystore (Redis) sur GCP. Vous pouvez l’adapter à vos besoins, l’enrichir ou le publier dans un wiki interne.
Documentation du Module Terraform GCP Redis (Cloud Memorystore)
Table des Matières

    Introduction
    Objectifs et Fonctionnalités
    Architecture et Concepts Clés
    Prérequis et Configuration
    Variables et Paramètres
    Maintenance, Persistance, Sécurité et Encryption
    Exemple d’Utilisation
    Bonnes Pratiques et Recommandations
    Dépannage (Troubleshooting)
    Références

1. Introduction

Ce module Terraform permet de déployer et de configurer automatiquement un service Cloud Memorystore for Redis sur Google Cloud Platform (GCP). Il gère :

    La création et la configuration de l’instance Redis (tier BASIC ou STANDARD_HA).
    L’activation de la persistance (RDB Snapshots), si nécessaire.
    La configuration de la fenêtre de maintenance.
    La gestion des accès réseau (VPC, firewall interne).
    La configuration optionnelle d’une clé KMS pour le chiffrement des données au repos (CMEK).

Grâce à ce module, vous pouvez automatiser la mise en place de Redis de manière reproductible, évolutive et sécurisée.
2. Objectifs et Fonctionnalités

    Création d’une instance Redis :
        Tier BASIC (instance unique) ou STANDARD_HA (haute disponibilité).
        Choix de la mémoire, de la version Redis, de la configuration interne (redis_configs).

    Réseau et connectivité :
        Possibilité de spécifier un VPC dédié (authorized_network).
        Choix du mode de connectivité (DIRECT_PEERING ou PRIVATE_SERVICE_ACCESS).
        Configuration optionnelle d’une règle firewall pour le trafic Redis (port 6379).

    Maintenance et patching :
        Définition d’une fenêtre de maintenance hebdomadaire (jour + heure/minute).

    Persistance (RDB Snapshots) :
        Désactivée par défaut ou déclenchée à intervalles réguliers (1 heure, 6 heures, etc.).

    Sécurité :
        Encryption in transit avec SERVER_AUTHENTICATION ou DISABLED.
        Encryption at rest :
            Par défaut, Google-managed encryption (DEK).
            Optionnellement, CMEK (Customer-Managed Encryption Key) via Cloud KMS.

    Réplicas en lecture (uniquement en STANDARD_HA) :
        Activation possible via read_replicas_mode et replica_count.

3. Architecture et Concepts Clés
3.1. Architecture Générale

    Module Terraform :
        Déploie un google_redis_instance sur GCP.
        Optionnellement, crée une ressource google_compute_firewall pour autoriser le trafic interne sur le port 6379.

    VPC :
        L’instance Redis réside dans un réseau VPC privé (autorisé par authorized_network).
        Pas d’accès public : la connexion se fait depuis des machines ou services au sein du même VPC ou via peering.

    Maintenance Policy :
        GCP applique automatiquement ses mises à jour ou patches lors de la fenêtre définie (jour et heure).

    Persistance RDB :
        Les snapshots sont sauvegardés selon une périodicité définie (1h, 6h, etc.).
        Les données sont stockées sur l’infrastructure Google (avec un chiffrement par défaut ou CMEK).

3.2. Concepts Clés

    Tier BASIC vs STANDARD_HA :
        BASIC : instance unique sans haute disponibilité.
        STANDARD_HA : réplique en mode failover automatique, plus robuste, surtout en production.

    Encryption in Transit :
        SERVER_AUTHENTICATION : active le chiffrement TLS lors de la connexion (clients doivent supporter TLS).
        DISABLED : pas de chiffrement en transit (intraflot VPC protégé par défaut).

    Chiffrement au Repos (At Rest) :
        DEK par défaut (Google-managed).
        CMEK (Customer-Managed Encryption Key) : clé KMS gérée par l’utilisateur, offrant plus de contrôle (révocation, rotation).

    Firewall :
        Contrôle l’accès réseau sur le port 6379.
        Fonctionne comme un “security group” en environnement GCP (règle google_compute_firewall).

4. Prérequis et Configuration

    Comptes et rôles GCP :
        Avoir un projet GCP actif.
        Disposer des rôles nécessaires (ex: roles/redis.admin, roles/compute.networkAdmin, roles/compute.securityAdmin, etc.).

    Terraform :
        Avoir Terraform version 1.x (de préférence >= 1.3).
        Installer le Provider Google : terraform init gérera ce point automatiquement.

    API GCP :
        Activer l’API Cloud Memorystore for Redis : gcloud services enable redis.googleapis.com.
        Si firewall activé : s’assurer que l’API compute.googleapis.com est également activée.

    Service Account (optionnel) :
        Si vous utilisez un compte de service et un fichier de clés JSON, préciser le chemin dans credentials.
        Le service account doit avoir les permissions pour créer/modifier des instances Redis, VPC, etc.

    Pour CMEK (facultatif) :
        Créer une clé KMS dans un key ring (ex: projects/<proj>/locations/<region>/keyRings/<ring>/cryptoKeys/<key>).
        Accorder l’accès roles/cloudkms.cryptoKeyEncrypterDecrypter au service account Redis (souvent service-<PROJECT_NUMBER>@cloud-redis.iam.gserviceaccount.com, ou le compte par défaut du projet).

5. Variables et Paramètres

Vous trouverez ci-dessous une vue d’ensemble des variables principales (cf. variables.tf complet dans le module) :
Variable	Type	Par défaut	Description
project_id	string	- (obligatoire)	ID du projet GCP
region	string	- (obligatoire)	Région GCP (ex: us-central1)
name	string	- (obligatoire)	Nom unique de l’instance Redis
tier	string	"BASIC"	Niveau de service (BASIC ou STANDARD_HA)
memory_size_gb	number	1	Taille mémoire en Go
redis_version	string	"REDIS_6_X"	Version Redis (ex: REDIS_5_0)
redis_configs	map(string)	{}	Clés/valeurs de configuration Redis
authorized_network	string | null	null	Réseau VPC (ex: projects/myproj/global/networks/default)
reserved_ip_range	string | null	null	CIDR réservé (ex: 10.0.0.0/29)
connect_mode	string	"DIRECT_PEERING"	DIRECT_PEERING ou PRIVATE_SERVICE_ACCESS
transit_encryption_mode	string	"DISABLED"	SERVER_AUTHENTICATION ou DISABLED
auth_enabled	bool	false	Active l’auth Redis (>=5.0)
read_replicas_mode	string	"READ_REPLICAS_DISABLED"	Active les réplicas en lecture si READ_REPLICAS_ENABLED (uniquement en STANDARD_HA)
replica_count	number	1	Nombre de réplicas en lecture
maintenance_day	string | null	null	Jour de maintenance (ex: TUESDAY)
maintenance_start_hour	number	3	Heure (0-23)
maintenance_start_minute	number	0	Minute (0-59)
persistence_mode	string	"DISABLED"	DISABLED ou RDB
rdb_snapshot_period	string	"SIX_HOURS"	ONE_HOUR, SIX_HOURS, TWELVE_HOURS, TWENTY_FOUR_HOURS, MANUAL
kms_key_name	string | null	null	Nom complet de la clé KMS pour CMEK (sinon DEK Google-managed)
create_firewall	bool	false	Créer une règle firewall interne pour autoriser le port 6379
firewall_name	string	"redis-firewall-rule"	Nom de la règle firewall
firewall_source_ranges	list(string)	["10.0.0.0/8"]	Plages IP autorisées
6. Maintenance, Persistance, Sécurité et Encryption
6.1. Maintenance Policy

    Maintenance_day : vous pouvez définir un jour de la semaine (ex: MONDAY).
    maintenance_start_hour / _minute : contrôlent l’heure UTC de début de la maintenance.
    Si maintenance_day est null, aucune fenêtre de maintenance n’est créée (GCP choisira la sienne).

6.2. Persistance (RDB Snapshots)

    persistence_mode = "DISABLED" ou "RDB".
    rdb_snapshot_period : cadence des snapshots (1h, 6h, 12h, etc.).
    GCP gère automatiquement les snapshots, qui sont stockés sur l’infrastructure Google.

6.3. Sécurité / Encryption

    Encryption in transit :
        DISABLED : pas de TLS.
        SERVER_AUTHENTICATION : TLS activé, les clients doivent supporter TLS.

    Encryption at rest :
        Par défaut : Google Data Encryption Key (DEK), géré automatiquement par Google.
        CMEK : via kms_key_name. Dans ce cas, vous devez avoir les droits KMS appropriés et la localisation compatible avec l’instance.

6.4. Firewall

    Pour restreindre l’accès au port Redis (6379), vous pouvez créer une ressource google_compute_firewall.
    Les IP sources autorisées doivent être dans firewall_source_ranges.
    N’oubliez pas de lier la règle au même network (VPC) que l’instance Redis.

7. Exemple d’Utilisation
7.1. Structure des fichiers

./
├── main.tf
├── variables.tf
├── outputs.tf
└── ...

    Ou vous placez ce module dans un dossier, par ex. modules/gcp-redis, et vous l’appelez depuis votre configuration principale.

7.2. Exemple de Configuration Terraform

provider "google" {
  project = "my-gcp-project"
  region  = "us-central1"
  # credentials = file("keys/serviceaccount.json")  # si nécessaire
}

module "redis_instance" {
  source = "./modules/gcp-redis"  # chemin vers votre module

  project_id = "my-gcp-project"
  region     = "us-central1"
  name       = "my-redis-production"

  tier            = "STANDARD_HA"
  memory_size_gb  = 2
  redis_version   = "REDIS_6_X"
  auth_enabled    = true

  authorized_network = "projects/my-gcp-project/global/networks/my-vpc"
  connect_mode       = "DIRECT_PEERING"
  transit_encryption_mode = "SERVER_AUTHENTICATION"

  maintenance_day         = "WEDNESDAY"
  maintenance_start_hour  = 2
  maintenance_start_minute= 30

  persistence_mode        = "RDB"
  rdb_snapshot_period     = "SIX_HOURS"

  # Exemple si vous ne voulez pas de firewall interne
  # create_firewall = false

  # Si vous souhaitez un firewall dédié
  create_firewall        = true
  firewall_name          = "redis-6379"
  firewall_source_ranges = ["10.128.0.0/16"]

  # CMEK (facultatif) : Définir la clé
  # kms_key_name = "projects/my-gcp-project/locations/us/keyRings/my-ring/cryptoKeys/my-redis-key"

  redis_configs = {
    "maxmemory-policy" = "allkeys-lru"
  }
}

output "redis_host" {
  value = module.redis_instance.redis_host
}

Commandes :

terraform init
terraform plan
terraform apply

Terraform créera alors l’instance Redis et, si configuré, la règle firewall interne.
8. Bonnes Pratiques et Recommandations

    Gestion des Credentials :
        N’incluez jamais vos credentials (fichiers JSON) dans un dépôt public.
        Privilégiez un backend remote sécurisé pour stocker le fichier terraform.tfstate.

    Contrôle de version :
        Fixez la version du Provider Google dans required_providers.
        Tenez à jour Terraform et vérifiez régulièrement les changements de la doc GCP.

    Haute Disponibilité :
        Préférez STANDARD_HA en production (résilience accrue).
        Vérifiez que la région choisie supporte la haute disponibilité.

    Maintenance Window :
        Ajustez la fenêtre de maintenance pour éviter les heures critiques de production.
        Surveillez les notifications Google en cas de MAJ.

    Persistance :
        Définissez RDB si vous avez besoin de garder des backups de vos données.
        Sachez que rdb_snapshot_period ne permet pas de choisir exactement l’heure de snapshot (c’est géré en interne par GCP).

    CMEK :
        Assurez-vous d’avoir configuré les rôles KMS nécessaires.
        La gestion du cycle de vie de la clé (rotation, révocation) vous incombe.

    Séparation des environnements :
        Utilisez des workspaces Terraform (prod, staging, dev) ou des projets GCP distincts.
        Évitez de mélanger plusieurs environnements dans le même état.

9. Dépannage (Troubleshooting)
Problème	Cause Possible	Solution
unsupported argument rdb_snapshot_interval	Ce champ n’existe plus ou n’a jamais été supporté en tant que paramètre modifiable.	Supprimer rdb_snapshot_interval ou utiliser rdb_snapshot_period.
unsupported block "customer_managed_key"	La version du provider Google n’est pas à jour ou la fonctionnalité est en bêta.	Mettre à jour le provider ou utiliser google-beta.
Impossible de définir start_time = "03:00"	La maintenance policy nécessite un bloc start_time { hours, minutes }.	Utiliser les variables maintenance_start_hour et maintenance_start_minute.
Erreur illegal rdb_snapshot_start_time	GCP considère souvent ce champ comme ReadOnly (ou nécessite format RFC3339).	Retirer rdb_snapshot_start_time et se fier au scheduling interne.
Accès au port Redis impossible	Pas de firewall configuré ou source_ranges incorrectes.	Vérifier create_firewall, firewall_source_ranges et le VPC.
Erreur d’autorisation KMS pour CMEK	Le SA Cloud Memorystore n’a pas le rôle cloudkms.cryptoKeyEncrypterDecrypter.	Accorder les rôles nécessaires via gcloud ou la console.
10. Références

    Terraform Google Provider :
    https://registry.terraform.io/providers/hashicorp/google/latest/docs

    Resource google_redis_instance :
    https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/redis_instance

    Cloud Memorystore for Redis Documentation :
    https://cloud.google.com/memorystore/docs/redis

    Gestion KMS (CMEK) :
    https://cloud.google.com/kms/docs

    Google Compute Firewall :
    https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall

Conclusion

Ce module Terraform propose un déploiement automatisé et sécurisé de Redis (Cloud Memorystore) sur GCP. Il inclut la configuration réseau, la politique de maintenance, la persistance des données, et la possibilité d’utiliser une clé KMS gérée par l’utilisateur pour le chiffrement au repos.
En suivant les bonnes pratiques décrites, vous assurerez une gestion efficace de votre infrastructure Redis, tout en profitant de la fiabilité et de la scalabilité de la plateforme Google Cloud.