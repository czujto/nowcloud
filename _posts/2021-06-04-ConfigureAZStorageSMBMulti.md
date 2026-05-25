---
layout: post
title: Azure Files SMB Multichannel
description: "Configuring Azure Files SMB Multichannel for premium Azure file shares and Windows clients."
categories: [Azure, Storage]
tags: [Azure, Azure Files, Networking, Azure Virtual Desktop]
excerpt_separator: <!--more-->
---
Azure Files SMB Multichannel (preview) enables an SMB 3.x client to establish multiple network connections to the premium file shares in a FileStorage account. 
Learn how to configure it!

![SMB Multichannel ]({{ site.baseurl }}/assets/img/blog/2021-06-06-ConfigureAZStorageSMBMulti/smb-multi1.jpg)

<!--more-->

> Updated note (2026): This article describes a preview-era configuration. Confirm current Azure Files support, limits and identity service names in Microsoft documentation before implementation.

Azure Files SMB Multichannel (preview) enables an SMB 3.x client to establish multiple network connections to the premium file shares in a FileStorage account. The SMB 3.x protocol introduced the SMB Multichannel feature in Windows Server 2012 and Windows 8 clients. Because of this, any Azure Files SMB 3.x client that supports SMB Multichannel can take advantage of the feature for their Azure premium file shares. There is no additional cost for enabling SMB Multichannel on a storage account.

At the time of writing, SMB Multichannel for Azure Files was in preview and had the limitations listed below:

+ Only supported for Windows clients.
+ Maximum number of channels is four.
+ SMB Direct is not supported.
+ Private endpoints for storage accounts are not supported.
+ For storage accounts with on-premises Active Directory Domain Services (AD DS) or Microsoft Entra Domain Services (formerly Azure AD DS) identity-based authentication enabled for Azure Files, SMB clients would not be able to use Windows File Explorer to configure NTFS permissions on directories and files.
+ Use Windows icacls tool or Set-ACL command instead to configure permissions.

SMB Multichannel for Azure files shares is available in all public cloud regions where premium file shares are available (LRS and ZRS)

Lets move on to the fun part, configuration!

First of all, we need to register for the SMB Multichannel preview. We can do it via Azure Portal by going to the Preview blade, selecting Join Azure Files SMB Multichannel preview and clicking Register.
Please bear in mind that registration might take up to an hour.

![SMB Multichannel ]({{ site.baseurl }}/assets/img/blog/2021-06-06-ConfigureAZStorageSMBMulti/smb-multi2.jpg) 	

To use PowerShell for registration, please run the commands below:

Connect-AzAccount
# Setting your active subscription to the one you want to register for the preview. 
# Replace the <subscription-id> placeholder with your subscription id. 
$context = Get-AzSubscription -SubscriptionId <your-subscription-id> 
Set-AzContext $context

Register-AzProviderFeature -FeatureName AllowSMBMultichannel -ProviderNamespace Microsoft.Storage 
Register-AzResourceProvider -ProviderNamespace Microsoft.Storage


You
Thanks!
