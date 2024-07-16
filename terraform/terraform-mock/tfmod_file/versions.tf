terraform {
  required_version = ">=1.3.2"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.2.3"
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 3.5.0"
    }
  }
}
