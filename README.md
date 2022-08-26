# DevOps-Trainee-Technical-Task
Description: The task consists of two scenarios. In the First scenario candidate should deploy 
infrastructure as described below (Picture 1) at Azure Cloud. Deployment must be performed via 
terraform (at least 1.0.0 version). The terraform code must cover all the required resources e.g. VNet, 
Subnet, etc.
Environment configuration:
- OS: Windows Server 2019;
- Traffic should be routed between two instances;
- VMs should be deployed to the different Availability zones
![зображення](https://user-images.githubusercontent.com/110202752/186844719-8089de9a-168f-4d08-9fe2-575e502134c9.png)
In the Second scenario candidate should develop PowerShell script that can deploy IIS website on VMs
created in the previous scenario. Each script run should clean up Website, Application Pool, and site 
folder. This PowerShell script should run on candidate’s local machine and connect to VMs via WinRM.
DoD: As a report, terraform code and working website screenshots should be uploaded to the GitLab
                      STEPS TO REPRODUCE
Steps to reproduce:

Deploy infrastructure with Terraform
Clone repository
Add VM1_Public_IP to TrustedHosts with command
Set-Item wsman:\localhost\client\TrustedHosts -Value VM1_Public_IP -Force
Add VM2_Public_IP to TrustedHosts with command
Set-Item wsman:\localhost\client\TrustedHosts -Value VM2_Public_IP -Force
Start installation of IIS on VM1 by invoking script Install-Webserver.ps1
Invoke-Command -ComputerName VM1_Public_IP -Credential VM1_Public_IP\demousr -FilePath PATH_To_Cloned_Repo:\Install-Webserver.ps1
Start installation of IIS on VM2 by invoking script Install-Webserver.ps1
Invoke-Command -ComputerName VM2_Public_IP -Credential VM2_Public_IP\demousr -FilePath PATH_To_Cloned_Repo:\Install-Webserver.ps1

END                      
