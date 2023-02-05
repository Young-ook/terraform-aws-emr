[[English](README.md)] [[한국어](README.ko.md)]

# EMR Bluprint
This is EMR Blueprint example helps you compose complete EMR clusters that are fully bootstrapped with the operational software that is needed to deploy and operate workloads. With this EMR Blueprint example, you describe the configuration for the desired state of your analytics platform with EMR clusters, such as the control plane, worker nodes, as an Infrastructure as Code (IaC) template/blueprint. Once a blueprint is configured, you can use it to stamp out consistent environments across multiple AWS accounts and Regions using your automation workflow tool, such as Jenkins, CodePipeline. Also, you can use EMR Blueprint to easily bootstrap an EMR cluster with a wide range of popular open-source analytics solutions such as Hadoop, Spark and more. EMR Blueprint also helps you implement relevant security controls needed to operate workloads from multiple teams in the same cluster.

## Setup
### Download
Download this example on your workspace
```
git clone https://github.com/Young-ook/terraform-aws-emr
cd terraform-aws-emr/examples/blueprint
```

Then you are in **blueprint** directory under your current workspace. There is an exmaple that shows how to use terraform configurations to create and manage an EMR cluster and utilities on your AWS account. Check out and apply it using terraform command. If you don't have the terraform tool in your environment, go to the main [page](https://github.com/Young-ook/terraform-aws-emr) of this repository and follow the installation instructions before you move to the next step.

Run terraform:
```
terraform init
terraform apply
```
Also you can use the *-var-file* option for customized paramters when you run the terraform plan/apply command.
```
terraform plan -var-file fixture.tc1.tfvars
terraform apply -var-file fixture.tc1.tfvars
```

## Clean up
To destroy all infrastrcuture, run terraform:
```
terraform destroy
```

If you don't want to see a confirmation question, you can use quite option for terraform destroy command
```
terraform destroy --auto-approve
```

**[DON'T FORGET]** You have to use the *-var-file* option when you run terraform destroy command to delete the aws resources created with extra variable files.
```
terraform destroy -var-file fixture.tc1.tfvars
```

# Additional Resources
## EMR Studio
- [Enable Interactive Data Analytics at Petabyte Scale with EMR Studio](https://youtu.be/A5nkJgSqw5c)
