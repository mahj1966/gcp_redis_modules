terraform {
  required_version = ">= 1.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.64" # or any recent 4.x version
    }
    # google-beta can be added if needed:
    # google-beta = {
    #   source  = "hashicorp/google-beta"
    #   version = "~> 4.64"
    # }
  }
}
