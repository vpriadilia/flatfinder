<img width="1232" height="552" alt="image" src="https://github.com/user-attachments/assets/e5f68f48-e9e3-4006-bb8c-70e27e9a754d" />

resource group: flatfinder-dev-rg

az deployment group what-if `
--resource-group flatfinder-dev-rg `
--template-file main.bicep `
--parameters main.biceppparam
