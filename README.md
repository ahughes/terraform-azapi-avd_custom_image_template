# Azure Virtual Desktop Custom Image Template Module

## Overview
This module creates an [AVD custom image template](https://learn.microsoft.com/en-us/azure/virtual-desktop/custom-image-templates) using the AzAPI provider.
It's essentially the Terraform replacement for the portal/UI steps documented [here](https://learn.microsoft.com/en-us/azure/virtual-desktop/create-custom-image-templates).

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azapi_resource.this](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | Name of the AVD Custom Image Template. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Location in which to deploy the AVD Custom Image Template. Shared images can be replicated by providing additional values within `var.distribute_shared_image.replicationRegions`. | `string` | n/a | yes |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | Resource Group ID (parent id of the AzAPI resource). | `string` | n/a | yes |
| <a name="input_user_assigned_identity_id"></a> [user\_assigned\_identity\_id](#input\_user\_assigned\_identity\_id) | ID of the user-assigned managed identity for AVD Custom Image Builder to use. Should have the recommended custom role assigned. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to the AVD Custom Image Template. An AVD\_IMAGE\_TEMPLATE tag will also be added automatically. | `map(string)` | `{}` | no |
| <a name="input_source_managed_image"></a> [source\_managed\_image](#input\_source\_managed\_image) | ID of a managed image to use as the source (starting) image. Required to have one of `var.source_managed_image`, `var.source_shared_image_version`, or `var.source_platform_image` defined. | <pre>object({<br>    type    = optional(string, "ManagedImage")<br>    imageId = string<br>  })</pre> | `null` | no |
| <a name="input_source_shared_image_version"></a> [source\_shared\_image\_version](#input\_source\_shared\_image\_version) | ID of a shared image version to use as the source (starting) image. Required to have one of `var.source_managed_image`, `var.source_shared_image_version`, or `var.source_platform_image` defined. | <pre>object({<br>    type           = optional(string, "SharedImageVersion")<br>    imageVersionId = string<br>  })</pre> | `null` | no |
| <a name="input_source_platform_image"></a> [source\_platform\_image](#input\_source\_platform\_image) | Details of a platform image to use as the source (starting) image. Required to have one of `var.source_managed_image`, `var.source_shared_image_version`, or `var.source_platform_image` defined. | <pre>object({<br>    type      = optional(string, "PlatformImage")<br>    publisher = string<br>    offer     = string<br>    sku       = string<br>    version   = optional(string, "latest")<br>  })</pre> | <pre>{<br>  "offer": "office-365",<br>  "publisher": "microsoftwindowsdesktop",<br>  "sku": "win10-22h2-avd-m365"<br>}</pre> | no |
| <a name="input_vm_profile"></a> [vm\_profile](#input\_vm\_profile) | Provide profile options for the VM created to build image. Omit to accept default values. | <pre>object({<br>    osDiskSizeGB = optional(number, 127)<br>    vmSize       = optional(string, "Standard_D1_v2")<br>    vnetConfig = optional(object({<br>      proxyVmSize = string<br>      subnetId    = string<br>    }), null)<br>  })</pre> | `{}` | no |
| <a name="input_build_timeout_in_minutes"></a> [build\_timeout\_in\_minutes](#input\_build\_timeout\_in\_minutes) | Optionally specify the timeout in minutes for the image build process. Omit or leave as 0 to prevent a timeout timer. | `number` | `0` | no |
| <a name="input_customizations"></a> [customizations](#input\_customizations) | Provide each of the customizations in it's corresponding type sub-object. Prefix the name (or map key) with numbers (and optional underscore) indicating priority. Customizations of all types will be combined, sorted, and then the prefixed priority will be trimmed. | <pre>object({<br>    files = optional(map(object({<br>      name        = optional(string) # Optional, defaults to map key<br>      destination = string<br>      sourceUri   = string<br>    })), {})<br>    powershell_inlines = optional(map(object({<br>      name        = optional(string) # Optional, defaults to map key<br>      runAsSystem = optional(bool, true)<br>      runElevated = optional(bool, true)<br>      inline      = list(string)<br>    })), {})<br>    powershell_scripts = optional(map(object({<br>      name        = optional(string) # Optional, defaults to map key<br>      runAsSystem = optional(bool, true)<br>      runElevated = optional(bool, true)<br>      scriptUri   = string<br>    })), {})<br>    windows_restarts = optional(map(object({<br>      name                = optional(string) # Optional, defaults to map key<br>      restartCheckCommand = optional(string, "")<br>      restartCommand      = optional(string, "")<br>      restartTimeout      = optional(string, "10m")<br>    })), {})<br>    windows_updates = optional(map(object({<br>      name = optional(string) # Optional, defaults to map key<br>    })), {})<br>  })</pre> | n/a | yes |
| <a name="input_distribute_managed_image"></a> [distribute\_managed\_image](#input\_distribute\_managed\_image) | Provide a managed image ID for distributing a completed/built image. | <pre>object({<br>    artifactTags  = optional(map(string), {})<br>    runOutputName = string<br>    type          = optional(string, "ManagedImage")<br>    imageId       = string<br>    location      = string<br>  })</pre> | `null` | no |
| <a name="input_distribute_shared_image"></a> [distribute\_shared\_image](#input\_distribute\_shared\_image) | Provide details of a shared image for distributing a completed/built image. | <pre>object({<br>    artifactTags       = optional(map(string), {})<br>    runOutputName      = string<br>    type               = optional(string, "SharedImage")<br>    excludeFromLatest  = optional(bool, false)<br>    galleryImageId     = string<br>    replicationRegions = list(string)<br>  })</pre> | `null` | no |

## Outputs

No outputs.
