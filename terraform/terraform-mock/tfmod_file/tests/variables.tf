variable "test_filenames" {
  description = "files in the module"
  type = map(object({
    filename             = string
    content              = string
    file_permission      = optional(string, "0644")
    directory_permission = optional(string, "0755")
  }))
}

variable "project_id" {
  description = "The id of the GCP  project."
  type        = string
}

variable "region" {
  description = "The region of the GCP project."
  type        = string
}

variable "bucket_name" {
  description = "The name of the bucket."
  type        = string
}
