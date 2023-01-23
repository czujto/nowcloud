---
layout: post
tags: [azure, Microsoft, Azure DevOps, DevOps]
title: How to deploy Terraform using Azure DevOps
excerpt_separator: <!--more-->
---
Azure DevOps is a powerful tool for managing and deploying code. One of the many features it offers is the ability to use Terraform to provision and manage infrastructure. In this blog post, we'll walk through the process of creating a new project in Azure DevOps and deploying Terraform code to it.

![AzureDevOps]({{ site.baseurl }}/assets/img/blog/2023-01-023-AzureDevOps/devops1.png)

<!--more-->

First, you'll need to create a new project in Azure DevOps. To do this, log in to your Azure DevOps account and click on the "Projects" button in the top right corner. Next, click on the "New project" button to create a new project. Give your project a name and select a template (if desired). 

![AzureDevOps]({{ site.baseurl }}/assets/img/blog/2023-01-023-AzureDevOps/devops2.png)

Once the project is created, you'll be taken to the project's dashboard.

Next, you'll need to create a new repository in the project to hold your Terraform code. To do this, click on the "Repos" button in the left sidebar. Then, click on the "New repository" button to create a new repository. Give your repository a name and select a version control system (such as Git).

![AzureDevOps]({{ site.baseurl }}/assets/img/blog/2023-01-023-AzureDevOps/devops3.png)

Don't forget to include Terraform in the .gitignore file, and also to add a README at the bottom of the repository page!

.gitignore is a file that tells git which files or directories to ignore when you commit changes to your repository. This is useful to ignore files that are specific to your environment or local machine and should not be tracked in the repository.

For Terraform, it is common practice to include the .terraform/ folder, terraform.tfstate, and terraform.tfstate.backup files in the .gitignore file. This is because the .terraform/ folder contains the local backend state, and the tfstate files contain the current state of your infrastructure, which is specific to your environment and shouldn't be committed to the repository. By including these files in the .gitignore file, you can ensure that they are not tracked by Git, and your repository remains clean and free of environment-specific files.

Once your repository is created, you can begin adding Terraform code to it. You can use the Azure DevOps web interface to add, edit, and commit your code, or you can use a local Git client and push your code to the repository.

Now that your Terraform code is in your repository, you can deploy it to your infrastructure. To do this, you'll need to create a new pipeline in Azure DevOps. A pipeline is a series of steps that are executed when code is committed to the repository. To create a new pipeline, click on the "Pipelines" button in the left sidebar. Then, click on the "New pipeline" button to create a new pipeline.

In the pipeline, you can configure Terraform to automatically provision and manage your infrastructure. To do this, you'll need to add a task to the pipeline that runs Terraform. Azure DevOps has a built-in Terraform task that you can use. You can configure this task to run Terraform init, plan, apply, and other Terraform command as per your requirement.

Once your pipeline is configured, you can run it to deploy your Terraform code to your infrastructure. You can also configure your pipeline to run automatically when code is committed to the repository.

In conclusion, Azure DevOps is a powerful tool for managing and deploying code. By creating a new project, repository, and pipeline in Azure DevOps, you can use Terraform to provision and manage your infrastructure in a reliable and efficient manner.