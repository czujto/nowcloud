---
layout: post
title: "Designing Pod-Based Global DNS for Azure Landing Zones"
date: 2026-05-26
description: "A practical architecture pattern for designing global DNS namespaces around platform pods, regions, environments and product teams in Azure landing zones."
categories:
  - azure
  - networking
tags:
  - azure-dns
  - private-dns
  - landing-zones
  - platform-engineering
  - global-dns
  - hub-and-spoke
permalink: /azure/networking/2026/05/26/designing-pod-based-global-dns-for-azure-landing-zones.html
---

As enterprise Azure estates grow, DNS moves from being an application configuration item to being a platform control plane. A useful namespace should express durable ownership and resolution boundaries across public services, private endpoints, hybrid networks and product landing zones.

<!--more-->

## Short answer

Pod-based global DNS organises an enterprise DNS namespace around stable platform units such as region, pod, environment, cloud provider or product boundary. It prevents each workload from inventing names independently and gives the platform a governed model for public and private resolution across Azure, hybrid networks and product teams.

The pattern makes delegation, RBAC, automation and troubleshooting align with platform operation.

## Problem

Many platforms begin with a few application-specific records: a public web name, perhaps a private database alias, and a small number of teams able to make DNS changes. The model becomes difficult once the estate includes multiple Azure regions, other clouds, sovereign or regulated boundaries, hub-and-spoke connectivity and broad use of Private Link.

Typical symptoms appear quickly:

- Names are inconsistent because every delivery team chooses a different convention.
- No one can explain clearly whether a DNS record belongs to the platform, the network team or a product owner.
- Public and private records are mixed without a documented split-horizon policy.
- Teams create duplicate private zones for the same Azure service.
- Product landing zones create unmanaged zones that do not resolve from shared or hybrid networks.
- Conditional forwarding from on-premises is introduced after applications already depend on private names.
- Private endpoints expose the missing DNS operating model because deployment succeeds while name resolution fails.

## What is a pod in platform DNS?

A pod is a stable platform unit used to group namespace, connectivity and ownership. It might represent a region, country, environment, cloud-provider boundary, product platform shard, regulated or sovereign boundary, or an operational ownership boundary.

A pod is not necessarily a Kubernetes pod. In this design it is an enterprise platform construct. For example, `zone1` may describe a platform boundary with a defined landing-zone pattern, resolver path and operating team. It remains meaningful even when applications, clusters or subscriptions are replaced.

A good pod label outlives an individual workload or deployment slot.

## Why DNS should follow platform boundaries

DNS names should communicate stable control boundaries rather than temporary projects. Operators investigating `api.app1.zone1.nowcloud.pl` can infer an application and a platform zone without being exposed to subscription IDs or implementation detail.

Ownership should follow the same structure. A central platform team can own `zone1.nowcloud.pl`, the pod capability and standard private endpoint zones. A delegated application team can manage approved records within its application scope through automation and limited RBAC. This gives autonomy without granting every workload the ability to build an unrelated DNS architecture.

> **Architecture takeaway:** Design DNS around boundaries that remain stable during application change: platform, pod, product, resolution visibility and operational ownership.

## Public DNS delegation model

Consider a public hierarchy:

```text
nowcloud.pl
|-- zone1.nowcloud.pl
|   `-- app1.zone1.nowcloud.pl
|-- zone2.nowcloud.pl
`-- zone3.nowcloud.pl
```

`nowcloud.pl` is the parent domain in this example. The domain owner may keep it with its registrar or existing public DNS provider. The parent can delegate `zone1.nowcloud.pl` to an Azure DNS public zone by publishing NS records that identify the authoritative Azure DNS name servers for the child zone. `zone2` and `zone3` illustrate other neutral platform or hyperscaler boundaries without exposing provider-specific naming.

Azure DNS hosts authoritative public DNS zones and their records; it is not the registrar that sells or registers `nowcloud.pl`. The platform therefore needs both ownership of the registered parent domain and a controlled process for adding delegations.

Public DNS is the correct place for public endpoints, public ingress, internet-facing service discovery and domain ownership validation. For example, an intentionally public API could use:

```text
api.app1.zone1.nowcloud.pl
```

> **Architecture takeaway:** Use public DNS delegation for public ownership boundaries. Do not use public DNS as a substitute for Private DNS resolution.

## Private DNS and split-horizon model

Public and private DNS can publish different answers for the same name or for related namespace branches. Azure Private DNS zones resolve from virtual networks linked to those zones, or from clients reaching an approved Azure resolution path. They are not internet-public DNS zones and are not delegated through public registrar NS records.

This distinction matters:

- Public delegation uses NS records in the public parent DNS hierarchy.
- Azure Private DNS visibility uses virtual network links and resolver architecture.
- Linking a private zone does not publicly delegate it.
- Delegating a public child zone does not make private records resolvable from landing-zone networks.

Split-horizon must be deliberate. If `app1.zone1.nowcloud.pl` exists as both a public and a private zone, clients with access to the private zone consult the private view for that namespace. They do not automatically fall back to the public zone for a missing `api` record. The platform must either publish an appropriate `api` record in both views or place private-only records in a narrower zone such as `internal.app1.zone1.nowcloud.pl`.

## Pod namespace example

The following model separates identity from connectivity:

| Purpose | Namespace example |
| --- | --- |
| Parent public domain | `nowcloud.pl` |
| Neutral platform zones | `zone1.nowcloud.pl`, `zone2.nowcloud.pl`, `zone3.nowcloud.pl` |
| Pod boundary used in this pattern | `zone1.nowcloud.pl` |
| Application boundary | `app1.zone1.nowcloud.pl` |
| Public application name | `api.app1.zone1.nowcloud.pl` |
| Private application names | `internal.app1.zone1.nowcloud.pl`, `db.app1.zone1.nowcloud.pl` |
| Azure SQL Private Link zone | `privatelink.database.windows.net` |
| Storage blob Private Link zone | `privatelink.blob.core.windows.net` |
| Key Vault Private Link zone | `privatelink.vaultcore.azure.net` |

Custom platform names and the Microsoft-recommended `privatelink.*` zones address different needs. A custom name communicates product and pod identity and can represent an internal application contract. A `privatelink.*` private zone enables standard Azure PaaS hostnames to resolve to private endpoint addresses for the corresponding Azure service.

Do not replace the required Azure Private Link service-zone pattern with a custom alias; applications often connect using the Azure service hostname.

## Hands-on implementation pattern

This is a reference implementation, not a copy-paste production design. It shows where public zones, private zones, resolver paths and validation records fit.

In this model:

- `nowcloud.pl` remains under registrar or parent DNS-provider control.
- `zone1.nowcloud.pl` is delegated to an Azure DNS public zone.
- `api.app1.zone1.nowcloud.pl` exists publicly only when the API is intentionally public.
- `app1.zone1.nowcloud.pl` is an Azure Private DNS split-horizon zone for internal client resolution.
- Microsoft `privatelink.*` zones remain separate Azure Private DNS zones for Azure private endpoints.
- Azure DNS Private Resolver provides controlled hybrid resolution paths through the connectivity hub.

### Step 1: Create or delegate the public platform zone

Create the public service zone in a platform-owned resource group. Azure DNS assigns authoritative name servers when the zone is created; those assigned servers must then be added as NS records at the parent `nowcloud.pl` provider.

```bash
az group create \
  --name rg-dns-public-platform \
  --location <azure-region>

az network dns zone create \
  --resource-group rg-dns-public-platform \
  --name zone1.nowcloud.pl

az network dns record-set ns show \
  --resource-group rg-dns-public-platform \
  --zone-name zone1.nowcloud.pl \
  --name @
```

Record the returned Azure name servers in the change request for the parent zone and delegate `zone1.nowcloud.pl` from `nowcloud.pl`. Do not copy sample Azure name-server values from a document; each created zone receives its authoritative values.

At the external DNS provider that hosts the parent `nowcloud.pl` zone, the delegation would look like this:

| Record name in `nowcloud.pl` | Type | Value supplied by Azure DNS |
| --- | --- | --- |
| `zone1` | `NS` | `ns1-01.azure-dns.com.` |
| `zone1` | `NS` | `ns2-01.azure-dns.net.` |
| `zone1` | `NS` | `ns3-01.azure-dns.org.` |
| `zone1` | `NS` | `ns4-01.azure-dns.info.` |

These name-server hostnames are illustrative only. Enter the exact four NS targets assigned to the created Azure DNS zone. Public queries below `zone1.nowcloud.pl` are then referred to Azure DNS, while `nowcloud.pl` remains with its existing provider.

Once delegation is effective, a deliberately public application name can be published in the delegated zone. A CNAME might point to a governed public ingress hostname, for example:

```bash
az network dns record-set cname set-record \
  --resource-group rg-dns-public-platform \
  --zone-name zone1.nowcloud.pl \
  --record-set-name api.app1 \
  --cname ingress.zone1.nowcloud.pl \
  --ttl 300
```

### Step 2: Establish the private pod/product view

For a deliberate split-horizon design, create a private zone for the product namespace and link only networks that need its private view:

```bash
az group create \
  --name rg-dns-private-zone1 \
  --location <azure-region>

az network private-dns zone create \
  --resource-group rg-dns-private-zone1 \
  --name app1.zone1.nowcloud.pl

az network private-dns link vnet create \
  --resource-group rg-dns-private-zone1 \
  --zone-name app1.zone1.nowcloud.pl \
  --name link-app1-spoke \
  --virtual-network /subscriptions/<subscription-id>/resourceGroups/rg-net-app1/providers/Microsoft.Network/virtualNetworks/vnet-app1-spoke \
  --registration-enabled false

az network private-dns record-set a add-record \
  --resource-group rg-dns-private-zone1 \
  --zone-name app1.zone1.nowcloud.pl \
  --record-set-name internal \
  --ipv4-address 10.42.10.20
```

Because this private zone covers the entire `app1` branch, linked networks will need an intentional answer for `api.app1.zone1.nowcloud.pl` if they must reach the public API by that name. Publish the appropriate internal-view record, or choose a narrower private zone such as `internal.app1.zone1.nowcloud.pl` when only internal names need private resolution.

### Step 3: Add Private Link DNS zones separately

Private endpoints for Azure PaaS services should integrate with the relevant Microsoft-recommended private zones. For example:

```bash
az network private-dns zone create \
  --resource-group rg-dns-private-zone1 \
  --name privatelink.database.windows.net

az network private-dns zone create \
  --resource-group rg-dns-private-zone1 \
  --name privatelink.blob.core.windows.net

az network private-dns zone create \
  --resource-group rg-dns-private-zone1 \
  --name privatelink.vaultcore.azure.net
```

Link these zones to the VNet that is the approved resolution point, often the connectivity hub when central resolution is used. Private endpoint deployment modules should create the endpoint and its DNS zone-group association as one supported action. A private endpoint without tested DNS resolution is not operationally complete.

### Step 4: Provide hub-and-spoke and hybrid resolution

In a hub-and-spoke model, deploy Azure DNS Private Resolver in a connectivity VNet with dedicated subnets for inbound and outbound endpoints. The inbound endpoint accepts queries from connected private locations, such as enterprise DNS servers over ExpressRoute or VPN. The outbound endpoint and forwarding rulesets route selected Azure-originated queries to approved DNS services, such as an on-premises namespace.

A typical operating path is:

```text
On-premises DNS
  -> conditional forward app1.zone1.nowcloud.pl
  -> Private Resolver inbound endpoint in the Azure hub
  -> private zone linked to the hub

Azure spoke
  -> linked forwarding ruleset or approved hub DNS path
  -> resolver and linked private zones
```

Keep resolver rules explicit. Forward the namespaces that require hybrid handling, and test both directions. If a ruleset forwards a private zone to an inbound endpoint, do not link that same rule back to the VNet containing the inbound endpoint, because that can form a DNS loop.

### Step 5: Publish public validation records when a service requires them

An application can be reachable privately while still requiring public proof that the organization controls a custom domain. Azure App Service custom-domain mapping is a useful example: validation is performed through public DNS, not an Azure Private DNS zone.

For an App Service subdomain such as `api.app1.zone1.nowcloud.pl`, the service may require:

```text
CNAME  api.app1  <app-service-default-hostname>
TXT    asuid.api.app1  <domain-verification-id>
```

For an apex mapping, the pattern uses an A record and an `asuid` TXT record. The exact record values come from the Azure resource configuration. Publish only the public records required for the intended public binding or verification; an `asuid` TXT record proves domain control and does not create private network reachability.

This separation is important for platform governance: public DNS owners approve externally visible verification and ingress records, while private DNS owners govern internal service discovery and private endpoint resolution.

### Step 6: Apply ownership, RBAC and operational tests

The platform team should own parent delegations, shared public zones, resolver architecture and approved `privatelink.*` zones. A product team can receive narrowly scoped permissions or an automated workflow to manage approved records within its product boundary. Avoid broad DNS Zone Contributor access across every pod when a smaller scope or deployment module is sufficient.

For each pod onboarding, test:

- Public NS delegation and public API resolution from an external resolver.
- Internal name resolution from the intended spoke VNet.
- Public-name behaviour from a VNet affected by split-horizon DNS.
- Azure PaaS hostname resolution to the expected private endpoint address.
- Conditional forwarding from a permitted hybrid client.
- Failure handling, record ownership metadata and removal of stale endpoints.

## Platform operating model

A namespace only remains governed when its delivery model is clear:

- The enterprise domain owner governs parent public-domain registration and delegation approval.
- The platform team defines pod naming, Azure DNS zones, Private Resolver deployment, Private Link zone patterns, RBAC and automation modules.
- Product teams request namespaces and endpoints through supported interfaces and validate application behaviour.
- Network operations own monitored resolver paths and hybrid forwarding runbooks.
- Security and governance functions review public exposure, privileged DNS changes and regulated-boundary exceptions.

Infrastructure as code should encode zones, links, endpoints, rules and role assignments, including pod ownership and permitted public names.

## Common failure modes

- Treating a pod label as a short-lived project name rather than a stable platform boundary.
- Creating public subdomains without documented delegation and ownership.
- Assuming an Azure Private DNS zone is delegated through internet DNS.
- Linking a private split-horizon zone and accidentally hiding a required public name.
- Replacing `privatelink.*` service zones with custom aliases without completing the Azure PaaS resolution path.
- Allowing each product subscription to create duplicate Private Link zones.
- Adding private endpoints without DNS zone-group and resolver-path testing.
- Building hybrid forwarding late, after products already depend on private resolution.
- Giving broad DNS administrative roles where pod- or workflow-scoped rights are sufficient.
- Publishing internal topology in public DNS when only validation or public ingress records are needed.

## Architecture checklist

- The global namespace uses stable cloud, pod and product boundaries.
- Parent public-zone ownership and NS delegation processes are documented.
- Public application records exist only for intentionally public services or required validation.
- Split-horizon zones define how public names behave from linked private networks.
- Private DNS zone links and Private Resolver paths are designed together.
- Microsoft-recommended `privatelink.*` zones are used for Azure PaaS private endpoints.
- Hub-and-spoke and hybrid queries are tested through approved resolver paths.
- RBAC, infrastructure as code and product onboarding reflect DNS ownership boundaries.
- Public TXT or CNAME/A verification records are managed as public-domain controls.
- Monitoring and runbooks cover resolution, endpoint lifecycle and recovery.

## Further reading

- [Azure DNS delegation overview](https://learn.microsoft.com/en-us/azure/dns/dns-domain-delegation)
- [Host and delegate a domain in Azure DNS](https://learn.microsoft.com/en-us/azure/dns/dns-delegate-domain-azure-dns)
- [Azure Private DNS overview](https://learn.microsoft.com/en-us/azure/dns/private-dns-overview)
- [Azure Private DNS virtual network links](https://learn.microsoft.com/en-us/azure/dns/private-dns-virtual-network-links)
- [Azure DNS Private Resolver endpoints and rulesets](https://learn.microsoft.com/en-us/azure/dns/private-resolver-endpoints-rulesets)
- [Azure DNS Private Resolver overview](https://learn.microsoft.com/en-us/azure/dns/dns-private-resolver-overview)
- [Azure Private Endpoint DNS configuration](https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns)
- [Azure App Service custom domain mapping](https://learn.microsoft.com/en-us/azure/app-service/app-service-web-tutorial-custom-domain)

## Related architecture notes

- [Private DNS at Scale in Azure Landing Zones]({% post_url 2026-05-25-private-dns-at-scale-in-azure-landing-zones %})
- [Designing Azure Landing Zones for Product Teams]({% post_url 2026-05-25-designing-azure-landing-zones-for-product-teams %})
- [Azure Networking](/azure-networking/)

## Summary

Pod-based global DNS gives Azure landing zones a namespace model that supports both scale and accountability. Public delegation exposes only intended public ownership and services; Private DNS, Private Link zones and Azure DNS Private Resolver deliver controlled private resolution across spokes and hybrid networks. With deliberate split-horizon rules, scoped RBAC and automated onboarding, DNS becomes a reliable platform capability rather than a set of workload exceptions.
