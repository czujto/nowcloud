---
layout: post
date: 2021-06-07
permalink: /azure/virtual desktop/2021/06/07/WVDRebrandingAVD.html
title: Windows Virtual Desktop became Azure Virtual Desktop
description: "The 2021 rebrand of Windows Virtual Desktop to Azure Virtual Desktop and its identity integration direction."
categories: [Azure, Virtual Desktop]
tags: [Azure, Azure Virtual Desktop, Microsoft Entra ID]
excerpt_separator: <!--more-->
---
In June 2021, Microsoft renamed Windows Virtual Desktop to Azure Virtual Desktop (AVD).

![WVD]({{ site.baseurl }}/assets/img/blog/2021-06-07-WVDRebrandingAVD/windows-virtual-desktop-wvd-logo-1.png)

<!--more-->

> Updated note (2026): Azure Virtual Desktop (AVD) is the current product name. Azure Active Directory referenced in this historical announcement is now Microsoft Entra ID.

Microsoft announced in June 2021 that Windows Virtual Desktop (WVD) would be rebranded as Azure Virtual Desktop (AVD).

The rebrand reflected Microsoft's broader positioning of the service as a cloud VDI and application-delivery platform for hybrid work. For enterprise architecture, the meaningful point was not simply the product name: AVD became an increasingly important platform workload requiring secure identity integration, scalable host management, profile storage, endpoint controls and monitoring.

At announcement time, Microsoft also described new capabilities and pricing options for remote application streaming.

Some of the capabilities discussed in that historical announcement included:

## Enhanced Support for Microsoft Entra ID

+ Microsoft Entra ID, then named Azure Active Directory, is a critical service used by organizations to manage user access to important apps and data and maintain strong security controls. At announcement time, Microsoft also described support for joining Azure Virtual Desktop virtual machines directly to that identity service.

## Multi-Session Management

+ Microsoft Endpoint Manager allows you to manage policies and distribute applications across devices.

Microsoft's original announcement is available in [Azure Virtual Desktop: The desktop and app virtualization platform for the hybrid workplace](https://azure.microsoft.com/en-us/blog/azure-virtual-desktop-the-desktop-and-app-virtualization-platform-for-the-hybrid-workplace/).

## Summary

Azure Virtual Desktop is now the established product name. For new deployments, focus on current AVD documentation and design the service as part of a governed Azure platform: identity, network paths, image management, user profiles, monitoring and operational ownership should be explicit from the start.
