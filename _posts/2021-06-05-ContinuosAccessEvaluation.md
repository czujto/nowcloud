---
layout: post
tags: [azure, Azure AD, Continuos Access Evaluation]
title: Enable Continuos Access Evaluation in Azure AD
excerpt_separator: <!--more-->
---
Continuous access evaluation (CAE) allows organizations to monitor near real-time critical events in Azure AD. 
Learn what the key benefits are and how to enable or disable CAE!


<!--more-->
CAE is implemented by enabling services, like Exchange Online, SharePoint Online, and Teams, to subscribe to critical events in Azure AD so that those events can be evaluated and enforced near real time. Critical event evaluation does not rely on Conditional Access policies so is available in any tenant. The following events are currently evaluated:

+ User Account is deleted or disabled
+ Password for a user is changed or reset
+ Multi-factor authentication is enabled for the user
+ Administrator explicitly revokes all refresh tokens for a user
+ High user risk detected by Azure AD Identity Protection

This process enables the scenario where users lose access to organizational SharePoint Online files, email, calendar, or tasks, and Teams from Microsoft 365 client apps within mins after one of these critical events.



#### Key benefits ####
+ User termination or password change/reset: User session revocation will be enforced in near real time.
+ Network location change: Conditional Access location policies will be enforced in near real time.
+ Token export to a machine outside of a trusted network can be prevented with Conditional Access location policies



#### Enable or disable CAE (Preview) ####

**1)** Sign in to the Azure portal as a Conditional Access Administrator, Security Administrator, or Global Administrator

**2)** Browse to Azure Active Directory > Security > Continuous access evaluation.

**3)** Choose Enable preview.

**4)** Select Save.


![CAE]({{ site.baseurl }}/assets/img/blog/2021-06-06-ContinuosAccessEvaluation/CAE2.PNG)

That's it done.

Thanks for reading!
