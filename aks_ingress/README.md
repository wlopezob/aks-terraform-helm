# Install AKS with Terraform
```
terraform init
terraform plan -out main.tfplan
terraform apply "main.tfplan"
```

## show ouput
```
terraform output
```

## upgrade providers
```
terraform init -upgrade
```

## set current subscription-id and get credentials aks
```
az account set --subscription {{subscription-id}}
az aks get-credentials --name wlopezob_aks --resource-group wlopezob_rg --overwrite-existing
```

## destroy resources
```
terraform plan -destroy -out main.destroy.tfplan
terraform apply main.destroy.tfplan
```