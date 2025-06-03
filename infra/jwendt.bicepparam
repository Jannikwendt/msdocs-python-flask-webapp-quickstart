using '../infra/main.bicep'

param location     = 'westeurope'
param acrName      = 'jwendtacr'
param planName     = 'jwendt-asp'
param webName      = 'jwendt-web'
param keyVaultName = 'jwendt-kv'
param spObjectId   = '25d8d697-c4a2-479f-96e0-15593a830ae5'
