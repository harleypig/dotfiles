variable "data_folder" {
  description = "Path for folders defined as YAML objects"
  type        = string
  default     = "myfolder"
}

variable "filename" {
  description = "The filename to be used"
  type        = string

  validation {
    condition     = contains(["filename1.txt", "filename2.txt"], var.filename)
    error_message = "Filename must be either 'filename1.txt' or 'filename2.txt'."
  }
}

# because we are modifying a key value in the object, we need to redefine the
# entire object

variable "files_from_yaml" {
  description = "files in the module"
  type = map(object({
    filename             = string
    content              = string
    file_permission      = string
    directory_permission = string
  }))
  
  validation {
    condition = alltrue([
      for filename, file in var.files_from_yaml : contains(["filename1.txt", "filename2.txt"], filename)
    ])
    error_message = "All filenames must be either 'filename1.txt' or 'filename2.txt'."
  }
}
