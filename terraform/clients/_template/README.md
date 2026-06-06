# Client Template — sGTM Onboarding

Copy this directory to create a new client deployment:

```bash
cp -r _template/ ../clients/<client-name>/
cd ../clients/<client-name>/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with the client's values
terraform init
terraform plan
terraform apply
```

## Prerequisites for each new client

1. GCP project with billing enabled
2. `gcloud auth application-default login` for the target project
3. GTM server container created → copy the Container Config string
4. DNS access for the client's domain (for the CNAME record)
5. Domain verified in Google Webmaster Central
