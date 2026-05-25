---
layout: post
title: Enable Continuous Access Evaluation in Microsoft Entra ID
description: "An introduction to Continuous Access Evaluation for identity-driven access enforcement in Microsoft Entra ID."
categories: [Azure, Identity]
tags: [Azure, Microsoft Entra ID, Continuous Access Evaluation, Conditional Access]
excerpt_separator: <!--more-->
---
Continuous Access Evaluation (CAE) allows organizations to monitor near real-time critical events in Microsoft Entra ID (formerly Azure Active Directory).
Learn what the key benefits are and how to enable or disable CAE!


<!--more-->

> Updated note (2026): Azure Active Directory is now Microsoft Entra ID. The portal experience and Continuous Access Evaluation capabilities have evolved since this preview-era article.

CAE is implemented by enabling services, like Exchange Online, SharePoint Online, and Teams, to subscribe to critical events in Microsoft Entra ID so that those events can be evaluated and enforced near real time. Critical event evaluation does not rely on Conditional Access policies so is available in any tenant. The following events are currently evaluated:

+ User Account is deleted or disabled
+ Password for a user is changed or reset
+ Multi-factor authentication is enabled for the user
+ Administrator explicitly revokes all refresh tokens for a user
+ High user risk detected by Microsoft Entra ID Protection

This process enables the scenario where users lose access to organizational SharePoint Online files, email, calendar, or tasks, and Teams from Microsoft 365 client apps within mins after one of these critical events.



#### Key benefits ####
+ User termination or password change/reset: User session revocation will be enforced in near real time.
+ Network location change: Conditional Access location policies will be enforced in near real time.
+ Token export to a machine outside of a trusted network can be prevented with Conditional Access location policies



#### Enable or disable CAE (Preview) ####

**1)** Sign in to the Azure portal as a Conditional Access Administrator, Security Administrator, or Global Administrator

**2)** Browse to Microsoft Entra ID > Security > Continuous access evaluation.

**3)** Choose Enable preview.

**4)** Select Save.


![CAE]({{ site.baseurl }}/assets/img/blog/2021-06-06-ContinuosAccessEvaluation/CAE2.PNG)

That's it done.

Thanks for reading!
