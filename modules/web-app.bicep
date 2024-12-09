

param name string
param location string = resourceGroup().location
param kind string
param serverfarmsResourceId string
param siteConfig object
param appSettingsKeyValuePairs object

resource webApp 'Microsoft.Web/site@2022-09-01' = {
  name: name
  location : location
  kind: kind
  properties : {
    serverFarmId : serverfarmsResourceId
    siteConfig: siteConfig
  }
}

resource WebAppSettings 'Microsoft.Web/config@2022-09-01' = {
  dependsOn: [
    webApp
  ]
  name : 'appsettings'
  properties : appSettingsKeyValuePairs
}
