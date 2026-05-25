---
layout: page
title: Identity and Security
description: "Microsoft Entra ID, privileged access and security guardrails for governed enterprise Azure platforms."
permalink: /identity-security/
show_author: true
---

Identity is the primary control plane for an Azure platform. It determines who can administer foundations, which workloads can reach services, how users authenticate to applications and how security teams respond when risk changes. In an enterprise architecture, identity and security are not a late-stage checklist: they are properties of the platform design and its day-to-day operating model.

Microsoft Entra ID (formerly Azure Active Directory) provides authentication and authorization capabilities that must be combined thoughtfully. Strong authentication, Conditional Access, privileged identity management, access reviews, break-glass procedures and workload identities each address a different risk. A platform team should establish patterns for human administration and application access, reduce permanent privilege and provide evidence of who can change critical infrastructure.

Landing zones are where many security intentions become enforceable. Management groups and subscriptions form authorization boundaries. Azure Policy can require diagnostics, prevent disallowed exposure or configurations and guide delivery toward approved services. Defender capabilities, security monitoring and centralized logging need a clear ownership model so findings are actionable rather than merely collected.

Identity is also fundamental to Azure Virtual Desktop and multi-tenant products. Virtual desktops may expose business systems from a flexible user access layer, so authentication strength, session policies and device conditions matter. Product platforms must distinguish tenant boundaries, operational administration and service-to-service access. Managed identities and carefully scoped roles reduce secret handling and clarify trust paths.

Regulated and sovereign platforms raise the demand for traceability. Administrators, deployment identities, external support paths and access from different locations need deliberate controls and auditable records. Policies and privileged workflows should be engineered consistently through infrastructure as code where possible, while exception handling remains explicit and reviewed.

Technology names evolve, but these architectural principles remain stable. Older articles on this site may use Azure AD terminology from the time of publication; current guidance uses Microsoft Entra ID and connects identity controls to governed Azure platform delivery.

A mature identity design is measurable: privileged assignments can be reviewed, risky access investigated, sign-in controls tested and workload permissions understood. Security architecture gains credibility when controls have both an owner and evidence.

## Related Articles

- [Enable Continuous Access Evaluation in Microsoft Entra ID]({% post_url 2021-06-05-ContinuosAccessEvaluation %}) covers identity-driven session enforcement.
- [Secure access to Azure Virtual Desktop with FIDO2 security keys]({% post_url 2021-06-06-WVDFIDO2 %}) explores phishing-resistant authentication for remote desktops.
- [Windows Virtual Desktop is rebranding]({% post_url 2021-06-07-WVDRebrandingAVD %}) includes identity integration context for AVD.
