variable "name" {
  type        = string
  description = "Repository name, without the owner."
}

variable "description" {
  type        = string
  description = "Repository description."
}

variable "topics" {
  type        = list(string)
  description = "Repository topics."
  default     = []
}

variable "required_checks" {
  type = list(object({
    context        = string
    integration_id = number
  }))
  description = "Status checks required before merging to main, each tied to the app that reports it."
}
