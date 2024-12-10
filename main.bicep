param location string
param acrName string
param appServicePlanName string
param webAppName string
param containerRegistryImageName string
param containerRegistryImageVersion string
param keyVaultName string

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

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
    value: containerRegistry.listCredentials().username
  }
  dependsOn: [
    keyVault
    acr
  ]
}

resource acrPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVaultReference
  name: 'acr-admin-password'
  properties: {
    value: containerRegistry.listCredentials().passwords[0].value
  }
  dependsOn: [
    keyVault
    acr
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

resource webAppIdentity 'Microsoft.Web/sites/config@2023-01-01' = {
  name: '${webAppName}/web'
  properties: {
    managedServiceIdentityId: 1
  }
  dependsOn: [
    webApp
  ]
}

resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, webAppName, 'AcrPull')
  scope: containerRegistry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalId: reference(resourceId('Microsoft.Web/sites', webAppName), '2023-01-01', 'full').identity.principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    webApp
    webAppIdentity
  ]
}
