# Introduction 
Walkthrough below explains how to use repo to deploy Azure SQL HAG in azure via TF code

# Architecture overview
Solution consists of following parts
- TF code for automation account holding compiled DSC scripts. Code lives under `.\modules\global `. Automation account since shared amongst deployments in subscription and regions
- SQL dsc script located under `./modules/sql/scripts` and named `sqlconfig_<version>.ps1`
- TF code to deploy Azure SQL VMs, compile DSC code and upload to Azure Automatino account under `.\modules\sql`

# Development setup
To ease develoment and enable fast rollback to check functionality of DSC following is advisable and verified setup
1. Create 2 virtual (internal only) switches in Hyper-V (since HAG using multi-subnet failover)
2. Create 2 Hyper-V VMs with Windows 2022/SQL 2019 (evaluation version is freeley availble) and deploy to each subnet
>Since subnets are internal they will not be able to talk to each other without router which will be setup next
3. Install Pfsense virtual firewall which will have 3 NICs, one which will be considered WAN and 2 of others will be on each subnet set up in step 1.
4. Configure pfSense firewall interfaces to enable routing between subnets. 
5. Following scripts are aiding in developing/debugging local DSC resources
   1. `./scripts/develop/run-prep.ps1` is a script to bootstrap nodes with prerequisites. It's the same script which is being used for bootstraping Azure VMs
   2. `./scripts/develop/run-config.ps1` scripts which compiles SQL DSC and pushes to VMs setup in step 2.
   
