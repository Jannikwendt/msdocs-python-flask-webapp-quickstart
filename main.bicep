param location string
param acrName string
param appServicePlanName string
param webAppName string
param containerRegistryImageName string
param containerRegistryImageVersion string
param keyVaultName string

module keyVault './modules/key-vault.bicep' = {
  name: 'keyVaultDeploy'
  params: {
    name: keyVaultName
    location: location
  }
}

resource keyVaultReference 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

module acr './modules/acr.bicep' = {
  name: 'acrDeploy'
  params: {
    name: acrName
    location: location
    acrAdminUserEnabled: true
  }
}

resource acrUsernameSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVaultReference
  name: 'acr-admin-username'
  properties: {
    value: acr.outputs.adminUsername
  }
  dependsOn: [
    keyVault
  ]
}

resource acrPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVaultReference
  name: 'acr-admin-password'
  properties: {
    value: acr.outputs.adminPassword
  }
  dependsOn: [
    keyVault
  ]
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
      DOCKER_REGISTRY_SERVER_USERNAME: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/acr-admin-username)'
      DOCKER_REGISTRY_SERVER_PASSWORD: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/acr-admin-password)'
    }
  }
  dependsOn: [
    acrUsernameSecret
    acrPasswordSecret
  ]
}
