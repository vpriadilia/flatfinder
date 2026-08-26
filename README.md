<img width="1134" height="826" alt="image" src="https://github.com/user-attachments/assets/b608e949-98b7-4673-87f0-73a09ac639b7" />

resource group: flatfinder-dev-rg

az deployment group what-if `
--resource-group flatfinder-dev-rg `
--template-file main.bicep `
--parameters main.biceppparam
