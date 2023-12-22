locals {
  example_name = "example"
  location     = "West US 3"
}

resource "azurerm_resource_group" "example" {
  name     = "${local.example_name}-rg"
  location = local.location
}

resource "azurerm_user_assigned_identity" "example" {
  name                = "${local.example_name}-id"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

data "azurerm_subscription" "current" {}

resource "azurerm_role_definition" "azure_image_builder" {
  name        = "Azure Image Builder"
  scope       = data.azurerm_subscription.current.id
  description = "Custom role used to distribute Azure Image Builder images."

  permissions {
    actions = [
      "Microsoft.Compute/galleries/read",
      "Microsoft.Compute/galleries/images/read",
      "Microsoft.Compute/galleries/images/versions/read",
      "Microsoft.Compute/galleries/images/versions/write",

      "Microsoft.Compute/images/write",
      "Microsoft.Compute/images/read",
      "Microsoft.Compute/images/delete"
    ]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.current.id
  ]
}

resource "azurerm_role_assignment" "azure_image_builder" {
  scope              = azurerm_resource_group.example.id
  role_definition_id = azurerm_role_definition.azure_image_builder.role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.example.principal_id
}

resource "azurerm_shared_image_gallery" "example" {
  name                = replace("${local.example_name}-gal", "-", "_")
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
}

resource "azurerm_shared_image" "avd_shared" {
  name                = local.example_name
  gallery_name        = azurerm_shared_image_gallery.example.name
  resource_group_name = azurerm_shared_image_gallery.example.resource_group_name
  location            = azurerm_shared_image_gallery.example.location
  os_type             = "Windows"
  description         = "${local.example_name} Windows image"

  identifier {
    publisher = local.example_name
    offer     = "${local.example_name}-offer"
    sku       = "${local.example_name}-sku"
  }
}

module "avd_custom_image_template" {
  source = "git::git@github.com:ahughes/terraform-azapi-avd_custom_image_template.git?ref=main"

  name                      = local.example_name
  resource_group_id         = azurerm_resource_group.example.id
  location                  = azurerm_resource_group.example.location
  user_assigned_identity_id = azurerm_user_assigned_identity.example.id

  source_platform_image = {
    publisher = "microsoftwindowsdesktop"
    offer     = "office-365"
    sku       = "win10-22h2-avd-m365"
  }

  customizations = {
    files = {
      "01_avdBuiltInScript_installLanguagePacks" = {
        destination = "C:\\AVDImage\\installLanguagePacks.ps1"
        sourceUri   = "https://raw.githubusercontent.com/Azure/RDS-Templates/master/CustomImageTemplateScripts/CustomImageTemplateScripts_2023-11-20/InstallLanguagePacks.ps1"
      }
      "06_avdBuiltInScript_removeAppxPackages" = {
        destination = "C:\\AVDImage\\removeAppxPackages.ps1"
        sourceUri   = "https://raw.githubusercontent.com/Azure/RDS-Templates/master/CustomImageTemplateScripts/CustomImageTemplateScripts_2023-11-20/RemoveAppxPackages.ps1"
      }
      "10_avdBuiltInScript_setDefaultLanguage" = {
        destination = "C:\\AVDImage\\setDefaultLanguage.ps1"
        sourceUri   = "https://raw.githubusercontent.com/Azure/RDS-Templates/master/CustomImageTemplateScripts/CustomImageTemplateScripts_2023-11-20/SetDefaultLang.ps1"
      }
      "12_avdBuiltInScript_windowsOptimization" = {
        destination = "C:\\AVDImage\\windowsOptimization.ps1"
        sourceUri   = "https://raw.githubusercontent.com/Azure/RDS-Templates/master/CustomImageTemplateScripts/CustomImageTemplateScripts_2023-11-20/WindowsOptimization.ps1"
      }
    }
    powershell_inlines = {
      "02_avdBuiltInScript_installLanguagePacks-parameter" = {
        inline = ["C:\\AVDImage\\installLanguagePacks.ps1 -LanguageList \"English (United States)\""]
      }
      "07_avdBuiltInScript_removeAppxPackages-parameter" = {
        inline = ["C:\\AVDImage\\removeAppxPackages.ps1 -AppxPackages \"Microsoft.windowscommunicationsapps\""]
      }
      "11_avdBuiltInScript_windowsOptimization-parameter" = {
        inline = ["C:\\AVDImage\\windowsOptimization.ps1 -Optimizations \"RemoveOneDrive\",\"RemoveLegacyIE\",\"DiskCleanup\",\"Edge\",\"LGPO\",\"NetworkOptimizations\",\"Services\",\"Autologgers\",\"WindowsMediaPlayer\",\"ScheduledTasks\",\"DefaultUserSettings\""]
      }
      "13_avdBuiltInScript_setDefaultLanguage-parameter" = {
        inline = ["C:\\AVDImage\\setDefaultLanguage.ps1 -Language \"English (United States)\""]
      }
    }
    powershell_scripts = {
      "05_avdBuiltInScript_fsLogixKerberos" = {
        scriptUri = "https://raw.githubusercontent.com/Azure/RDS-Templates/master/CustomImageTemplateScripts/CustomImageTemplateScripts_2023-11-20/FSLogixKerberos.ps1"
      }
      "16_avdBuiltInScript_timeZoneRedirection" = {
        scriptUri = "https://raw.githubusercontent.com/Azure/RDS-Templates/master/CustomImageTemplateScripts/CustomImageTemplateScripts_2023-11-20/TimezoneRedirection.ps1"
      }
    }
    windows_restarts = {
      "04_avdBuiltInScript_installLanguagePacks-windowsRestart" = {}
      "09_avdBuiltInScript_windowsUpdate-windowsRestart"        = {}
      "15_avdBuiltInScript_setDefaultLanguage-windowsRestart" = {
        restartTimeout = "5m"
      }
    }
    windows_updates = {
      "03_avdBuiltInScript_installLanguagePacks-windowsUpdate" = {}
      "08_avdBuiltInScript_windowsUpdate"                      = {}
      "14_avdBuiltInScript_setDefaultLanguage-windowsUpdate"   = {}
    }
  }

  distribute_shared_image = {
    galleryImageId     = azurerm_shared_image.example.id
    replicationRegions = [azurerm_resource_group.example.location]
    runOutputName      = local.example_name
  }
}
