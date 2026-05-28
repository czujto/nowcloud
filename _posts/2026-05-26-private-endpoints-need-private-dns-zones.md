---
layout: post
title: "Private Endpoints Need Private DNS Zones"
date: 2026-05-26
description: "A practical Azure landing zone note explaining why private endpoints are incomplete without correct Private DNS zones, VNet links and resolver paths."
categories:
  - azure
  - networking
tags:
  - private-endpoint
  - private-dns
  - azure-dns
  - azure-landing-zones
  - platform-engineering
permalink: /azure/networking/2026/05/26/private-endpoints-need-private-dns-zones.html
---

Private connectivity is not complete when an endpoint resource exists in the portal. It is complete when the intended clients can resolve the service name correctly and use the private path reliably.

<!--more-->

## Short answer

When an app stops working, it is always DNS.

Except when it is networking.

Except in Azure, where it is often both - because somebody created a Private Endpoint and forgot that DNS is now part of the deployment.

A Private Endpoint is not a complete deployment until clients resolve the service name to the private endpoint IP from the networks that need to use it. In Azure landing zones, Private DNS zones, virtual network links and resolver paths are part of the architecture, not an optional afterthought.

Private Endpoint plus broken DNS is incomplete private connectivity. The resource may be provisioned successfully, and routing may be available, but an application that resolves the public path or cannot resolve the service at all will not consume the intended private endpoint.

## Series context

This is Part 1 of the **Azure DNS for Landing Zones** series.

- Part 1: Private Endpoints Need Private DNS Zones
- Part 2: [Private DNS at Scale in Azure Landing Zones]({% post_url 2026-05-25-private-dns-at-scale-in-azure-landing-zones %})
- Part 3: Designing Pod-Based Global DNS for Azure Landing Zones — coming after that

Part 1 focuses on the smallest useful design decision: whenever a workload is expected to use a private endpoint, its name-resolution path must be designed and tested with the endpoint.

## The mistake

The familiar sequence is deceptively simple:

1. A product team creates a private endpoint for an Azure service.
2. The endpoint receives a private IP address in the workload network.
3. Routing, network security and public-access settings appear correct.
4. The application still cannot connect, or connects through a path that was not intended.

The investigation often begins with firewalls, user-defined routes, private endpoint approval or application credentials. Those may matter, but the basic question should come first: what IP address does the application actually receive when it resolves the Azure service hostname?

The failure is often that DNS still returns an unsuitable public path, that the required Private DNS zone was never created or linked, or that a central resolver cannot see the private zone. Another common failure is a locally created zone in one subscription while workloads elsewhere use a different resolution path.

> **The private endpoint changes the network path, but DNS decides whether the application uses that path.**

This is why a private endpoint must not be treated as a stand-alone application resource. In a landing-zone architecture it consumes shared network and DNS capabilities.

## How Private Endpoint DNS works

Applications usually continue to use an Azure service's normal hostname. A storage client does not need a new bespoke application setting merely because a blob endpoint becomes private. Instead, Azure Private Link relies on DNS resolution producing the private endpoint path for networks that are allowed to use it.

For Blob Storage, the Microsoft-recommended Private DNS zone is:

```text
privatelink.blob.core.windows.net
```

The intended private-resolution sequence is:

```text
Application in product spoke VNet
  -> resolves the storage service hostname
  -> Private DNS resolution reaches privatelink.blob.core.windows.net
  -> private A record returns 10.40.10.20
  -> application connects to the private endpoint IP
```

The private A record maps the private-link service name to the endpoint network interface address. A private DNS zone group associated with the private endpoint can manage the relevant record association when it is configured against the correct zone.

The details matter:

- The public Azure service FQDN may remain the application-facing name.
- The recommended `privatelink.*` zone supports correct private endpoint resolution for that service type.
- A VNet linked to the Private DNS zone can resolve records in the zone when it uses the Azure-provided DNS path.
- A network using custom DNS, central forwarding or hybrid connectivity needs an approved resolver path to the linked zone.
- Public DNS and Azure Private DNS are different control planes. A public service name does not make a private record visible, and a private zone is not published to the internet.

Do not invent a custom substitute for the service's required `privatelink.*` zone simply to make the naming look tidy. Custom application aliases can be useful at another layer, but the platform still needs the Azure Private Endpoint DNS integration required by the service.

## What the platform should own

At enterprise scale, individual workload teams should not each decide how Azure Private Link DNS works. The platform team should own or govern the reusable resolution capability:

- Approved `privatelink.*` Private DNS zones for supported Azure service types.
- A central DNS resource group or subscription where central ownership is appropriate.
- The virtual network link strategy: which hub, spoke or resolution VNets can query each zone.
- Azure DNS Private Resolver and hybrid forwarding paths where workloads or on-premises networks need them.
- Policy and deployment guardrails that prevent unsupported DNS patterns.
- Naming, RBAC and ownership metadata for platform DNS resources.
- Cleanup processes so deleted or replaced private endpoints do not leave stale private records.

Central ownership does not mean a manual ticket for every endpoint. The preferred model is a supported infrastructure-as-code module or deployment workflow that allows a product team to request a private endpoint while the platform pattern supplies the approved DNS association.

Where a shared connectivity hub provides DNS resolution, Private DNS zones may be linked to the hub or other approved resolution VNet. Spoke and hybrid clients then reach the private answer through the documented resolver path. The design should make that path visible to support teams and testable from workloads.

## What the product team should own

The application or product team remains accountable for why private connectivity is required and whether the application actually works through it. It should own:

- The justified request for a private endpoint.
- The Azure service instance consumed by the application.
- The workload connectivity requirement and permitted source networks.
- Application connection configuration and secret handling.
- Testing name resolution and connectivity from the workload network.
- A lifecycle or decommissioning request when the endpoint is no longer needed.

This separation avoids two poor outcomes: unrestricted DNS sprawl in product subscriptions and a platform team that becomes responsible for application behavior it cannot validate.

## Minimal implementation pattern

Consider a generic product workload that accesses a storage account through Blob Storage:

| Item | Example |
| --- | --- |
| Azure service | Storage account Blob endpoint |
| Required Private DNS zone | `privatelink.blob.core.windows.net` |
| Workload network | Product spoke VNet |
| Private endpoint IP | `10.40.10.20` |
| Platform DNS resource group | `rg-dns-private-platform` |
| Workload resource group | `rg-product-network` |

This is a reference pattern rather than a complete production deployment. Subscription boundaries, access control, region, monitoring and infrastructure-as-code implementation should follow the platform standard.

### 1. Create or use the approved private zone

The platform either provisions this zone once for the supported service type or reuses the approved centrally governed zone:

```bash
az network private-dns zone create \
  --resource-group rg-dns-private-platform \
  --name privatelink.blob.core.windows.net
```

Avoid a separate copy of the same service zone in every product subscription unless the architecture deliberately requires isolated DNS boundaries and documents how clients select the correct zone.

### 2. Make the zone resolvable from the intended network

For a direct spoke-resolution pattern, link the product spoke VNet to the zone without VM autoregistration:

```bash
az network private-dns link vnet create \
  --resource-group rg-dns-private-platform \
  --zone-name privatelink.blob.core.windows.net \
  --name link-product-spoke-blob \
  --virtual-network /subscriptions/<subscription-id>/resourceGroups/rg-product-network/providers/Microsoft.Network/virtualNetworks/vnet-product-spoke \
  --registration-enabled false
```

This is a resolution link: the workload can query records in the private zone, while the link is not intended to register ordinary VM hostnames.

In a centrally resolved hub-and-spoke design, do not blindly link every zone to every spoke. Link zones and configure resolver paths according to the agreed model. If custom DNS or hybrid networks are involved, clients may need Azure DNS Private Resolver inbound endpoints and conditional forwarding rather than a direct spoke link.

### 3. Associate the endpoint with the private DNS zone

After the product's private endpoint has been created, associate it with the approved zone through a private DNS zone group:

```bash
az network private-endpoint dns-zone-group create \
  --resource-group rg-product-network \
  --endpoint-name pe-product-blob \
  --name default \
  --private-dns-zone /subscriptions/<platform-subscription-id>/resourceGroups/rg-dns-private-platform/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net \
  --zone-name blob
```

The DNS zone group is the integration point between the endpoint and the platform-owned zone. The platform workflow should ensure that the endpoint type is paired with the correct recommended zone, rather than asking product teams to guess the mapping.

For the example endpoint, the private zone should contain the private record associated with `10.40.10.20`. In a managed deployment this record is produced through the zone-group association; manually entered records should be reserved for carefully governed cases where automation is not suitable.

### 4. Verify resolution from the workload network

Run the test from a compute resource that uses the same DNS path as the application, not only from an administrator workstation:

```bash
nslookup <storage-account-name>.blob.core.windows.net
```

The result should lead to the intended private endpoint address:

```text
Name:    <storage-account-name>.privatelink.blob.core.windows.net
Address: 10.40.10.20
```

Also test the application connection, public-access policy behavior and any hybrid source networks that are expected to consume the private service. A successful private IP lookup confirms DNS behavior; it does not replace end-to-end connectivity testing.

### 5. Document ownership and cleanup

For each endpoint, record:

- Product or workload owner.
- Service type and required private DNS zone.
- Spoke or resolver path used for name resolution.
- Endpoint and DNS zone group resource ownership.
- Expected private IP or validation method.
- Removal process when the service is retired.

Private endpoints have a lifecycle. DNS associations and stale records must be removed when endpoints are replaced or deleted, or troubleshooting becomes harder and name resolution can become misleading.

## Resolver paths in hub-and-spoke landing zones

A small Azure-only deployment may work with a Private DNS zone linked directly to one spoke VNet. Enterprise landing zones often need a broader pattern:

```text
Product spoke VNet
  -> approved Azure DNS resolution path
  -> Private DNS zone linked to resolution VNet
  -> private endpoint record

On-premises client
  -> enterprise DNS conditional forwarder
  -> Azure DNS Private Resolver inbound endpoint
  -> Private DNS zone linked in Azure
  -> private endpoint record
```

Azure DNS Private Resolver supplies managed inbound and outbound endpoints and forwarding rulesets. An inbound endpoint enables connected networks to query Azure private zones through a controlled Azure path. An outbound endpoint and linked ruleset enable Azure networks to forward selected namespaces to approved DNS servers elsewhere.

This does not remove design responsibility. The platform must decide where the resolver is deployed, which networks can reach it, which zones are linked, how forwarding is monitored and how a secondary region or recovery scenario behaves.

## Centralised Private DNS with Azure Firewall DNS Proxy

A Private Endpoint DNS design does not always require linking the `privatelink.*` zone to every spoke VNet. In a classic hub-and-spoke Azure landing zone, one option is to link required Private DNS zones to the hub or DNS platform VNet, configure Azure Firewall as a DNS proxy, and configure spoke VNets to use the Azure Firewall private IP address as their DNS server.

Azure Firewall DNS Proxy acts as an intermediary. A spoke workload sends a DNS query to the firewall private IP, and the firewall forwards that query to its configured upstream DNS server. When the upstream path can resolve the platform-owned Private DNS zones, the product spoke receives the private endpoint answer through one centrally governed DNS path.

Instead of making every spoke a direct resolution link:

```text
Private DNS zone
  -> linked to every spoke VNet
```

The platform can use this pattern where appropriate:

```text
Spoke VM / workload
  -> DNS query to Azure Firewall private IP
  -> Azure Firewall DNS Proxy
  -> upstream DNS that can resolve Azure Private DNS zones
  -> private A record / Private Endpoint IP
```

This option can reduce Private DNS zone virtual network link sprawl, maintain a consistent DNS view between Azure Firewall FQDN rules and clients, simplify platform governance and reduce the temptation for workload subscriptions to create duplicate private zones.

It is not a universal rule. The following constraints are important:

- Spoke workloads must actually use the Azure Firewall private IP as their DNS server.
- The upstream DNS configured on Azure Firewall must be able to resolve the required Private DNS zones.
- When Azure Firewall uses Azure-provided DNS upstream, the required zone must be linked to the VNet context from which that Azure DNS query can resolve it.
- When Azure Firewall uses a custom DNS server upstream, that server must resolve or correctly forward queries toward the Azure Private DNS zones.
- DNS Proxy does not combine every zone in the tenant. It forwards each client query to the configured upstream DNS path.
- In an Azure Virtual WAN secured hub design, Microsoft-managed secured virtual hubs cannot be linked directly to Private DNS zones. A DNS extension VNet with a resolver or forwarder pattern may be required.
- This design centralises DNS dependency on the hub and firewall path, so availability, logging, operations and recovery ownership must be planned.

> Architecture takeaway: Azure Firewall DNS Proxy can reduce Private DNS zone link sprawl by making spokes use a central DNS path, but only when the firewall's upstream resolver can actually resolve the linked Private DNS zones.

### Azure Firewall DNS Proxy implementation pattern

1. Enable DNS Proxy on Azure Firewall.
2. Configure spoke VNet DNS servers to use the Azure Firewall private IP.
3. Link required Azure Private DNS zones to the hub or DNS platform VNet.
4. Ensure Azure Firewall upstream DNS can resolve those zones.
5. Restart or renew DNS configuration on VMs after VNet DNS server changes.
6. Verify resolution from a workload VM in a spoke VNet.

The firewall-side configuration is intentionally concise:

```bash
az network firewall update \
  --name <firewall-name> \
  --resource-group <firewall-rg> \
  --enable-dns-proxy true
```

Configure the spoke VNet to send DNS queries to the firewall private IP:

```bash
az network vnet update \
  --name vnet-product-spoke \
  --resource-group rg-product-network \
  --dns-servers <azure-firewall-private-ip>
```

After the VNet DNS setting is updated, renew the guest network configuration or restart test VMs as required, then validate the storage lookup from the spoke:

```bash
nslookup <storage-account-name>.blob.core.windows.net
```

The expected answer remains the private endpoint address, such as `10.40.10.20`. The difference is that the client reaches that answer through Azure Firewall DNS Proxy and its resolvable upstream path instead of through a direct zone link in every spoke.

## Troubleshooting order

When an application fails after private endpoint deployment, use an order that reflects the architecture:

1. Resolve the service hostname from the workload network.
2. Confirm the answer is the intended private endpoint IP.
3. Confirm the private DNS zone is the correct Microsoft-recommended zone for the service.
4. Confirm the zone group and relevant VNet link or resolver path exist.
5. Only then continue with routes, network security, firewall policy, service approval and application authentication.

This order is not a claim that every outage is DNS. It is a way to avoid spending an hour inspecting a route table when the client never attempted to use the private address.

## Common failure modes

- A private endpoint is created without a DNS zone group.
- The wrong `privatelink.*` zone is selected for the service subresource.
- A product subscription creates an unmanaged duplicate private zone.
- The approved zone exists but is not visible through the workload's VNet link or resolver path.
- Hybrid DNS is expected to resolve Azure private endpoints without conditional forwarding to Azure.
- A record remains after an endpoint is removed or replaced.
- Engineers validate the endpoint resource but do not test DNS from the application network.

Each failure can be prevented through a platform module, policy checks, ownership records and a DNS-first validation step in release testing.

## Architecture checklist

- The private endpoint request includes the required DNS integration.
- The service uses the appropriate Microsoft-recommended `privatelink.*` zone.
- Zone ownership and RBAC are defined by the platform.
- The workload network can reach a linked-zone or resolver-based resolution path.
- Zone-group association is created and governed alongside the endpoint.
- Resolution is tested from the application network and any approved hybrid source.
- Cleanup is part of the endpoint lifecycle.
- Troubleshooting runbooks check resolution before deeper network diagnosis.

## Further reading

- [Azure Private Endpoint DNS configuration](https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns)
- [Azure Private Endpoint DNS integration scenarios](https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns-integration)
- [Azure Private DNS virtual network links](https://learn.microsoft.com/en-us/azure/dns/private-dns-virtual-network-links)
- [Azure DNS Private Resolver endpoints and rulesets](https://learn.microsoft.com/en-us/azure/dns/private-resolver-endpoints-rulesets)
- [Azure Firewall DNS settings](https://learn.microsoft.com/en-us/azure/firewall/dns-settings)
- [Azure Firewall DNS Proxy details](https://learn.microsoft.com/en-us/azure/firewall/dns-details)
- [Private endpoint inspection in an Azure Virtual WAN secured hub](https://learn.microsoft.com/en-us/azure/firewall-manager/private-link-inspection-secure-virtual-hub)
- [Azure CLI private endpoint DNS zone groups](https://learn.microsoft.com/en-us/cli/azure/network/private-endpoint/dns-zone-group)

## Related architecture notes

- [Azure Networking](/azure-networking/)
- [Private DNS at Scale in Azure Landing Zones]({% post_url 2026-05-25-private-dns-at-scale-in-azure-landing-zones %})
- Designing Pod-Based Global DNS for Azure Landing Zones - coming after that.

## Summary

A Private Endpoint delivers a private network attachment, not a finished application connection. The finished pattern includes the approved Private DNS zone, the correct record association, a VNet link or resolver path and a test from the network where the application runs. Treating these elements as one platform capability is the difference between private connectivity that is repeatable and private connectivity that fails only after deployment.
