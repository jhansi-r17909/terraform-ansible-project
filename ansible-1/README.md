# Ansible configuration

This playbook configures the EC2 instance created by Terraform as a single-node Minikube host and installs Helm.

## Run locally

```powershell
cd infra
terraform init
terraform apply -var-file="terraform.tfvars"

cd ../ansible
ansible-playbook playbook.yml
```
