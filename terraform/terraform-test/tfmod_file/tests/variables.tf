variable "test_filenames" {
  description = "files in the module"
  type = map(object({
    filename             = string
    content              = string
    file_permission      = optional(string, "0644")
    directory_permission = optional(string, "0755")
  }))
}
