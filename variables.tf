variable "name" {
  description = "Name of the AVD Custom Image Template."
  type        = string
}
variable "location" {
  description = "Location in which to deploy the AVD Custom Image Template. Shared images can be replicated by providing additional values within `var.distribute_shared_image.replicationRegions`."
  type        = string
}
variable "resource_group_id" {
  description = "Resource Group ID (parent id of the AzAPI resource)."
  type        = string
}
variable "user_assigned_identity_id" {
  description = "ID of the user-assigned managed identity for AVD Custom Image Builder to use. Should have the recommended custom role assigned."
  type        = string
}
variable "tags" {
  description = "Map of tags to apply to the AVD Custom Image Template. An AVD_IMAGE_TEMPLATE tag will also be added automatically."
  type        = map(string)
  default     = {}
}

# Source Image
variable "source_managed_image" {
  description = "ID of a managed image to use as the source (starting) image. Required to have one of `var.source_managed_image`, `var.source_shared_image_version`, or `var.source_platform_image` defined."
  type = object({
    type    = optional(string, "ManagedImage")
    imageId = string
  })
  default = null
}
variable "source_shared_image_version" {
  description = "ID of a shared image version to use as the source (starting) image. Required to have one of `var.source_managed_image`, `var.source_shared_image_version`, or `var.source_platform_image` defined."
  type = object({
    type           = optional(string, "SharedImageVersion")
    imageVersionId = string
  })
  default = null
}
variable "source_platform_image" {
  description = "Details of a platform image to use as the source (starting) image. Required to have one of `var.source_managed_image`, `var.source_shared_image_version`, or `var.source_platform_image` defined."
  type = object({
    type      = optional(string, "PlatformImage")
    publisher = string
    offer     = string
    sku       = string
    version   = optional(string, "latest")
  })
  default = {
    publisher = "microsoftwindowsdesktop"
    offer     = "office-365"
    sku       = "win10-22h2-avd-m365"
  }
}

# Image Build Settings
variable "vm_profile" {
  description = "Provide profile options for the VM created to build image. Omit to accept default values."
  type = object({
    osDiskSizeGB = optional(number, 127)
    vmSize       = optional(string, "Standard_D1_v2")
    vnetConfig = optional(object({
      proxyVmSize = string
      subnetId    = string
    }), null)
  })
  default = {}
}
variable "build_timeout_in_minutes" {
  description = "Optionally specify the timeout in minutes for the image build process. Omit or leave as 0 to prevent a timeout timer."
  type        = number
  default     = 0
}

#Customizations
variable "customizations" {
  description = "Provide each of the customizations in it's corresponding type sub-object. Prefix the name (or map key) with numbers (and optional underscore) indicating priority. Customizations of all types will be combined, sorted, and then the prefixed priority will be trimmed."
  type = object({
    files = optional(map(object({
      name        = optional(string) # Optional, defaults to map key
      destination = string
      sourceUri   = string
    })), {})
    powershell_inlines = optional(map(object({
      name        = optional(string) # Optional, defaults to map key
      runAsSystem = optional(bool, true)
      runElevated = optional(bool, true)
      inline      = list(string)
    })), {})
    powershell_scripts = optional(map(object({
      name        = optional(string) # Optional, defaults to map key
      runAsSystem = optional(bool, true)
      runElevated = optional(bool, true)
      scriptUri   = string
    })), {})
    windows_restarts = optional(map(object({
      name                = optional(string) # Optional, defaults to map key
      restartCheckCommand = optional(string, "")
      restartCommand      = optional(string, "")
      restartTimeout      = optional(string, "10m")
    })), {})
    windows_updates = optional(map(object({
      name = optional(string) # Optional, defaults to map key
    })), {})
  })
}

# Distribute Images
variable "distribute_managed_image" {
  description = "Provide a managed image ID for distributing a completed/built image."
  type = object({
    artifactTags  = optional(map(string), {})
    runOutputName = string
    type          = optional(string, "ManagedImage")
    imageId       = string
    location      = string
  })
  default = null
}
variable "distribute_shared_image" {
  description = "Provide details of a shared image for distributing a completed/built image."
  type = object({
    artifactTags       = optional(map(string), {})
    runOutputName      = string
    type               = optional(string, "SharedImage")
    excludeFromLatest  = optional(bool, false)
    galleryImageId     = string
    replicationRegions = list(string)
  })
  default = null
}
