# Air-Gapped Terraform Config

This will deploy a set of servers and a bastion "jump-box" to simulate an
air-gapped installation. 

## Requirements

An ssh keypair needs to be generated. By default the
`var.ssh_private_key_file` and `var.ssh_public_key_file` are set to
`./airgap-ssh.pem` and `./airgap-ssh.pub` respectivly. To customize edit variables.tf.

## Applying with cloud-cleaner tags

Additional `aws_tags` can be specified on apply to play nicely with
`cloud-cleaner`:

```bash
  terraform apply -var 'aws_tags={"owner"="my_name","expiration"="10h"}' ag.tfplan
```

## Setup

A new VPC will be created with two subnets `public` and `private`. An internet
gateway is created and a default route is *ONLY* created on the `public`
subnet. Security groups are configured such that the nodes in the `private`
subnet can only send traffic to and from the `private` subnet. Traffic can
also be sent to the public subnet, and only ssh connections are allowd from
the `public` subnet. This in effect creates a set of nodes that are completly
decoupled from the internet.

In the public subnet, a jumpbox or bastion is created and Terraform remotely 
executes to configures bastion system and downloads a set of packages. 
The Terraform automation is acapable of create a local container registry
fto serve the private subnet.

In the private subnet, a cluster bootstrap node is created and disables all
existing yum repos, and installs a single repo that points to the jumpbox. 
This allows dependancies of the bundled packages in konvoy to be resolved 
automatically, but it also requires that the jumpbox and the cluster nodes
use the same version of centos.

## Known issues and workarounds
To connect to the bootstrap node, use shh-add to cache the ssh key defined in
variables.tf

```bash
ssh-add -D && ssh-add ./airgap-ssh.pem
```

The docker registry running on the `jumpbox` will need to be manually seeded
with the required images.

This requires Terraform 0.11.x

## Initialize terraform
```bash
export TF_VAR_profile_id="${AWS_PROFILE}"
export TF_VAR_region_id="${AWS_DEFAULT_REGION}"
                          
terrafrom init
```

## Generate plan
```bash
terraform plan -out=ag.tfplan
```

## Apply plan
```bash
terraform apply ag.tfplan
```

## Destroy cluster
```bash
terraform destroy --force
```
