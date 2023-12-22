locals {
  customizations = concat(
    # Files
    [for file_key, file in var.customizations.files : {
      type        = "File"
      name        = coalesce(file.name, file_key)
      destination = file.destination
      sourceUri   = file.sourceUri
    }],
    # PowerShell (Inline)
    [for ps_inline_key, ps_inline in var.customizations.powershell_inlines : {
      type        = "PowerShell"
      name        = coalesce(ps_inline.name, ps_inline_key)
      runAsSystem = ps_inline.runAsSystem # Default: true
      runElevated = ps_inline.runElevated # Default: true
      inline      = ps_inline.inline
    }],
    # PowerShell (Script)
    [for ps_script_key, ps_script in var.customizations.powershell_scripts : {
      type        = "PowerShell"
      name        = coalesce(ps_script.name, ps_script_key)
      runAsSystem = ps_script.runAsSystem # Default: true
      runElevated = ps_script.runElevated # Default: true
      scriptUri   = lookup(ps_script, "scriptUri", null)
    }],
    # WindowsRestart
    [for windows_restart_key, windows_restart in var.customizations.windows_restarts : {
      type                = "WindowsRestart"
      name                = coalesce(windows_restart.name, windows_restart_key)
      restartCheckCommand = windows_restart.restartCheckCommand # Default: ""
      restartCommand      = windows_restart.restartCommand      # Default: ""
      restartTimeout      = windows_restart.restartTimeout      # Default: "10m"
    }],
    # WindowsUpdate
    [for windows_update_key, windows_update in var.customizations.windows_updates : {
      type = "WindowsUpdate"
      name = coalesce(windows_update.name, windows_update_key)
    }],
    # Default Final Admin SysPrep Customization
    [{
      type        = "PowerShell"
      name        = "999_avdBuiltInScript_adminSysPrep"
      runAsSystem = true
      runElevated = true
      scriptUri   = "https://raw.githubusercontent.com/Azure/RDS-Templates/master/CustomImageTemplateScripts/CustomImageTemplateScripts_2023-11-20/AdminSysPrep.ps1"
    }]
  )
  sorted_customizations = flatten(
    [for name in sort(flatten(local.customizations.*.name)) : # Sort all of the combined customizations lexicographically (by name/key)
      [for customization in local.customizations :            # Loop through the sorted list of names and select the corresponding full customization object
        merge(                                                # Trim the prefixed priority numbers (and optional underscore) if needed
          customization,
          {
            name = regex("^(?:\\d+_?)?(\\D.*)$", customization.name)[0]
          }
        ) if customization.name == name
      ]
    ]
  )
  body = jsonencode({
    properties = {
      source                = coalesce(var.source_managed_image, var.source_shared_image_version, var.source_platform_image)
      vmProfile             = var.vm_profile
      buildTimeoutInMinutes = var.build_timeout_in_minutes
      customize             = local.sorted_customizations
      distribute = concat(
        var.distribute_managed_image != null ? [var.distribute_managed_image] : [],
        var.distribute_shared_image != null ? [var.distribute_shared_image] : []
      )
    }
  })
}
resource "azapi_resource" "this" {
  type      = "Microsoft.VirtualMachineImages/imageTemplates@2020-02-14"
  name      = var.name
  location  = var.location
  parent_id = var.resource_group_id
  tags      = merge(var.tags, { "AVD_IMAGE_TEMPLATE" = "AVD_IMAGE_TEMPLATE" })

  identity {
    type         = "UserAssigned"
    identity_ids = [var.user_assigned_identity_id]
  }

  body = local.body
}
