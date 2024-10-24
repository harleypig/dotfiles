variable "file_path" {
  description = "Path to the file to be read"
  type        = string
}

data "local_file" "file_content" {
  filename = var.file_path
}

output "file_content" {
  value = data.local_file.file_content.content
}
