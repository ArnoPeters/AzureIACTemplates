[[_TOC_]]

This chapter contains instructions for new developers on how to setup a working development environment for this repository, and how the build/release process is arranged.

# Overview
This repo contains reusable templates for Azure Deployments. The goal is to provide a uniform baseline in naming conventions and security settings of the building bricks that are used to build Azure infrastructure. The templates are intended as a starting point. 

# Local Development

## Recommmended Tooling
- [Visual Studio Code](https://code.visualstudio.com/).   
The repository contains Arm & Bicep templates, and VS Code extension recommendations that provide intellisense and help with template development have been included in the /.vscode folder of the repo.   
**These extensions are not available for Visual Studio itself!** 

## Prerequisites
- TODO: 
- Azure CLI

### Keys and Secrets
Please do not put secrets and Azure access keys in code or configuration. 
KeyVault secrets are available in local development and Azure keys kan be stored in the [local Secret Manager](https://docs.microsoft.com/en-us/aspnet/core/security/app-secrets). 

## Building the code
- No special steps needed.  

## Debugging locally or against a development environment
- TODO:
  

## Running Tests
- No special steps needed. 

### UI Tests
- N/A

# Releasing

## Dependencies on other repositories

- The repository makes use of the YAML templates for releases and pipelines in the ```Pipelines``` repository.

## Versioning
- TODO: describe gitversion setup
  _TODO: Example: when using Gitversion, point to pull request template and gitversion.yml on how to bump version numbers_

## Pipelines
The repo uses the following build/release pipelines: 
- azure-pipelines.yml: deploys the Bicep and Arm templates as Template Specs to a resource group in Azure. 
