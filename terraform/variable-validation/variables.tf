variable "data_folder" {
  description = "Path for folders defined as YAML objects"
  type        = string
  default     = "myfolder"
}

variable "filename_pattern" {
  description = "Pattern for filenames"
  type        = string
  default     = "^filename[0-9]+\\.txt$"
}
