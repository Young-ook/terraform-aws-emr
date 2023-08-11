[[English](README.md)] [[한국어](README.ko.md)]

# Amazon EMR Studio
[Amazon EMR](https://aws.amazon.com/emr/) is the industry-leading cloud big data solution for petabyte-scale data processing, interactive analytics, and machine learning using open-source frameworks such as Apache Spark, Apache Hive, and Presto.

[Amazon EMR Studio](https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-studio.html) is a web-based integrated development environment (IDE) for fully managed Jupyter notebooks that run on Amazon EMR clusters. EMR Studio makes it easy for data scientists and data engineers to develop, visualize, and debug applications written in R, Python, Scala, and PySpark. EMR Studio is integrated with AWS Identity and Access Management (IAM) and IAM Identity Center so users can log in using their corporate credentials. EMR Studio provides fully managed Jupyter Notebooks and tools such as Spark UI and YARN Timeline Service to simplify debugging. Data scientists and analysts can install custom kernels and libraries, collaborate with peers using code repositories such as GitHub and BitBucket, or execute parameterized notebooks as part of scheduled workflows using orchestration services like Apache Airflow or [Amazon Managed Workflows for Apache Airflow](https://aws.amazon.com/managed-workflows-for-apache-airflow/).

EMR Studio kernels and applications run on EMR clusters, so you get the benefit of distributed data processing using the performance optimized [Amazon EMR runtime for Apache Spark](https://aws.amazon.com/about-aws/whats-new/2019/11/announcing-emr-runtime-for-apache-spark/). Administrators can set up EMR Studio such that analysts can run their applications on existing EMR clusters or create new clusters using pre-defined AWS Cloud Formation templates for EMR.

## Setup
### Prerequisites
This module requires *terraform*. If you don't have the terraform tool in your environment, go to the main [page](https://github.com/Young-ook/terraform-aws-emr) of this repository and follow the installation instructions.

# Additional Resources
## Amazon EMR Serverless
- [EMR Serverless Samples](https://github.com/aws-samples/emr-serverless-samples)
## Amazon EMR Studio
- [Enable Interactive Data Analytics at Petabyte Scale with EMR Studio](https://youtu.be/A5nkJgSqw5c)

