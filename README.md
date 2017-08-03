## Basic Two-Tier AWS Architecture

This project provides a template for running a simple two-tier architecture on Amazon
Web services.

Running this code will deploy into AWS

* A Virtual Private Cloud (VPC)

* Two subnets within the VPC
  * Public: A publically accessible subnet
  * Private: A private subnet which is only accessible within the VPC

* Gateways and routes
  * Public: A non-NAT gateway and routes for the public subnet to this gateway
  * Private: A NAT gateway and routes for the private subnet to this gateway

* Instances
  * A bastion jumphost on the public subnet exposed via Elastic IP
  * A private host on the private network which is only reachable via the bastion jumphost.


## How to Use This

```
# Edit variables.tv to set AWS credentials and other custom options
emacs variables.tf

# Check terraform
terraform plan

# Deploy or Update resources
terraform apply

# Remove all resources
terraform destroy
```

## License

MIT License
