param location string
param acrName string
param appServicePlanName string
param webAppName string
param containerRegistryImageName string
param containerRegistryImageVersion string
param JanniksKeyVault string  // Added parameter for Key Vault

module acr './modules/acr.bicep' = {
  name: 'acrDeploy'
  params: {
    name: acrName
    location: location
    acrAdminUserEnabled: true
  }
}

module appServicePlan './modules/app-service-plan.bicep' = {
  name: 'appServicePlanDeploy'
  params: {
    name: appServicePlanName
    location: location
    sku: {
      name: 'B1'
      tier: 'Basic'
      size: 'B1'
      family: 'B'
      capacity: 1
    }
  }
}

module webApp './modules/web-app.bicep' = {
  name: 'webAppDeploy'
  params: {
    name: webAppName
    location: location
    kind: 'app'
    serverfarmsResourceId: appServicePlan.outputs.planId
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acr.outputs.loginServer}/${containerRegistryImageName}:${containerRegistryImageVersion}'
      appCommandLine: ''
    }
    appSettingsKeyValuePairs: {
      WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'false'
      DOCKER_REGISTRY_SERVER_URL: 'https://${acr.outputs.loginServer}'
      DOCKER_REGISTRY_SERVER_USERNAME: '@Microsoft.KeyVault(SecretUri=https://${JanniksKeyVault}.vault.azure.net/secrets/acr-admin-username)'  // Updated with Key Vault reference
      DOCKER_REGISTRY_SERVER_PASSWORD: '@Microsoft.KeyVault(SecretUri=https://${JanniksKeyVault}.vault.azure.net/secrets/acr-admin-password)'  // Updated with Key Vault reference
    }
  }
}

