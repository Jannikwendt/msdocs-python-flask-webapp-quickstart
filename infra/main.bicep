param location      string = 'westeurope'
param acrName       string = 'jwendtacr'
param planName      string = 'jwendt-asp'
param webName       string = 'jwendt-web'
param keyVaultName string          // name passed from jwendt.bicepparam
param spObjectId  string           // objectId of the service principal


var linuxSku = {
  name: 'B1'
  tier: 'Basic'
  size: 'B1'
  family: 'B'
  capacity: 1
}

// ---------- Key Vault ----------
module kv './key-vault.bicep' = {
  name: 'kv'
  params: {
    location:  location
    vaultName: keyVaultName
    spObjectId: spObjectId          // ← fixed
  }
}


/* ------------ Container Registry ------------ */
resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: acrName
  location: location
  sku: { name: 'Basic' }
  properties: { adminUserEnabled: true }
  dependsOn: [ kv ]
}

/* store creds in the vault */
resource secretUser 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: 'acr-username'
  parent: kv
  properties: { value: acr.listCredentials().username }
}
resource secretPwd  'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: 'acr-password1'
  parent: kv
  properties: { value: acr.listCredentials().passwords[0].value }
}

/* ------------ Linux App Service Plan ------------ */
resource plan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: planName
  location: location
  kind: 'linux'
  sku: linuxSku
  properties: { reserved: true }
}

/* ------------ Web App ------------ */
resource web 'Microsoft.Web/sites@2022-09-01' = {
  name: webName
  location: location
  kind: 'app'
  properties: {
    serverFarmId: plan.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acrName}.azurecr.io/flaskweb:latest'
      appSettings: [
        { name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE' value: 'false' }
        { name: 'DOCKER_REGISTRY_SERVER_URL'          value: 'https://${acrName}.azurecr.io' }
        { name: 'DOCKER_REGISTRY_SERVER_USERNAME'     value: secretUser.properties.value }
        { name: 'DOCKER_REGISTRY_SERVER_PASSWORD'     value: secretPwd.properties.value }
      ]
    }
  }
  dependsOn: [ plan , acr ]
}
