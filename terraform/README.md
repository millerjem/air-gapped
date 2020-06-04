# Air-Gapped Terraform Config

This will deploy a set of servers and a bation "jump-box" to simulate an
air-gapped installation. 

## Requirements

An ssh keypair needs to be generated. By default the
`var.ssh_private_key_file` and `var.ssh_public_key_file` are set to
`./id_mesosphere` and `./id_mesosphere.pub` respectivly. To customize edit variables.tf.

## Applying with `cloud-cleaner` tags

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

In the `public` subnet a `jumpbox` bastion is launched in the public subnet. A
`user_data` script is created for the `jumpbox` which configures yum repos and
then downloads a set of packages from them to cache. It then creates a local
repo from those cached packages and serves the out to the private subnet. A
docker registry is also configured on the `jumpbox`.


In the `private` subnet, the `bootstrap` node is launched as
well as an ELB to sit infront of the `bootstrap`. On all the
`bootstrap` instance a `user_data` script is created that
disables all existing yum repos, and installs a single repo that points to
the jumpbox. This allows dependencies of the bundled packages in `konvoy` to
be resolved automatically, but it also requires that the `jumpbox` and the
cluster nodes use the same version of centos.

## Known issues and workarounds
To connect to the bootstrap node, use shh-add to cache the ssh key defined in
variables.tf
```bash
ssh-add -D && ssh-add ./id_mesosphere
```

The docker registry running on the `jumpbox` will need to be manually seeded
with the required images.

## Initialize terraform

```bash
docker run -i -t -v $(pwd):/tf --workdir=/tf hashicorp/terraform:light init
```

## Generate plan

You can run build the simple plan:

```bash
docker run -i -t -v $(pwd):/tf --workdir=/tf hashicorp/terraform:light plan -out=ag.tfplan
```

-or-

Add some extra vars.

```bash
docker run -i -t -v $(pwd):/tf --workdir=/tf hashicorp/terraform:light plan -var 'aws_tags={"owner"="my_name","expiration"="10h"}' -var 'cluster_name="air_gap_test"' -out=ag.tfplan
```

Note: This will ask for your ~/.aws/credential sets if you don't have them in you ENV. 
The environment variables must be in the format `TF_VAR_name` and this will be checked last for a value

You could also modify the `main.tf` with an explicit aws shared credentials file.

```json
provider "aws" {
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "customprofile"
}
```

## Apply plan

```bash
docker run -i -t -v $(pwd):/tf --workdir=/tf hashicorp/terraform:light apply ag.tfplan
```

## Connect to the AirGap Machine

* `54.185.129.50` is the External IP of the Public Node
* `10.0.0.233` is the Internal IP of the Private(AirGap) Node

Example: 
`ssh -o 'ProxyCommand ssh -W %h:%p -i id_mesosphere centos@54.185.129.50' -i id_mesosphere centos@10.0.0.233`

## Destroy cluster

```bash
docker run -i -t -v $(pwd):/tf --workdir=/tf hashicorp/terraform:light destroy --force
```


