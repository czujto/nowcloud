---
layout: post
date: 2026-05-25
permalink: /azure/networking/2026/05/25/private-dns-at-scale-in-azure-landing-zones.html
title: "Private DNS at Scale in Azure Landing Zones"
description: "An architecture approach to Azure Private DNS, private endpoints and hybrid name resolution across enterprise landing zones."
categories: [Azure, Networking]
tags: [Azure, Private DNS, Private Endpoints, Azure Landing Zones, Networking]
excerpt_separator: <!--more-->
last_modified_at: 2026-05-25
---

Private endpoints are straightforward to demonstrate in one virtual network. Across many subscriptions, products, environments and connected networks, private DNS becomes one of the most important shared services in an Azure platform.

<!--more-->

## Short answer

Private DNS at Azure landing-zone scale is a shared platform capability that ensures private endpoint names resolve consistently from workload, hub and hybrid networks through centrally governed zones and resolution paths.

## Architecture decision

Centralise ownership of approved Azure Private DNS zones and resolver patterns, while enabling product teams to provision supported private endpoints through automated platform interfaces.

## When to use this pattern

Use this pattern when private endpoints span multiple subscriptions or virtual networks, when hybrid systems must resolve Azure private services, or when consistent private connectivity is required for regulated workloads.

## Why Private DNS Becomes Hard at Scale

When an Azure service receives a private endpoint, applications still normally address the service using its familiar service hostname. DNS must guide that name to the private endpoint address from approved networks. In a small proof of concept, linking one private DNS zone to one virtual network can appear sufficient. In an enterprise platform, that approach quickly encounters ownership, duplication, hybrid resolution and lifecycle problems.

Product teams may create endpoints for storage, Key Vault, databases, container registries and other services in separate subscriptions. Environments may require isolation. On-premises systems may need to reach selected private services. Central networking teams need to understand the resulting paths without manually administering every application deployment.

Private DNS is therefore not just a network configuration detail. It is a platform capability that influences security boundaries, reliability and product-team autonomy.

> **Architecture takeaway:** Private DNS must be designed as a shared platform service once workloads consume private endpoints across subscriptions and networks.

## Private Endpoints and Split-Horizon DNS

A private endpoint maps an Azure service into a virtual network using a private IP address. Public DNS for the service continues to exist, while the private resolution path should return the endpoint address for clients that are intended to reach it privately. This is a split-horizon DNS problem: the correct answer depends on where the query originates and what access path is approved.

If name resolution is incorrect, clients may fail to connect, attempt a public path that policy prohibits, or reach the wrong endpoint arrangement. These failures are often misdiagnosed as firewall or application issues.

A platform design should treat endpoint provisioning and DNS registration as one capability. Creating a private endpoint without the intended resolution path is not a completed deployment.

## Centralised Private DNS Zones

In a multi-subscription estate, Azure Private DNS zones are usually best owned centrally in a connectivity or shared-services subscription. Central ownership reduces duplicated zones, inconsistent records and uncertainty over which virtual networks are linked to which resolution source.

The platform can establish zones for approved Azure Private Link services and control zone links to the networks that require them. Product automation creates private endpoints and associates them with the supported central DNS pattern rather than creating arbitrary local zones.

Centralisation does not mean that the networking team must manually approve every routine endpoint. Terraform modules or deployment workflows can expose supported endpoint types and register them consistently. The division is useful: the platform owns resolution architecture, while the product owns its service instance and justified connectivity request.

> **Architecture takeaway:** Central ownership should be paired with automation, so consistent resolution does not become a manual delivery bottleneck.

Environment separation requires deliberate thought. Some organizations use common central zones across environments where access and routing already provide adequate separation; others require stronger isolation. The decision should follow security and operational requirements rather than happen accidentally through portal defaults.

## Private DNS Zone Sharding

Central ownership does not always require one flat zone shared across every product and environment. Private DNS zone sharding is an architecture pattern, not an Azure feature toggle: the platform deliberately establishes smaller resolution boundaries based on product or team ownership, environment, region, service type or workload lifecycle.

<figure class="architecture-diagram">
  <img src="{{ '/assets/img/diagrams/private-dns-zone-sharding.svg' | relative_url }}" alt="Private DNS zone sharding pattern for Azure landing zones with Azure DNS Private Resolver, sharded private DNS zones, selective virtual network links and product spoke networks.">
  <figcaption>
    Private DNS zone sharding keeps central DNS governance while reducing change blast radius through selective virtual network links and ownership-based DNS boundaries.
  </figcaption>
</figure>

Sharded zones are isolated by default, so cross-zone and hybrid resolution must be designed explicitly. Azure DNS Private Resolver supports hub-and-spoke and hybrid paths across approved DNS boundaries, while selective virtual network links limit which workloads consume each shard. Linking every spoke to every zone removes much of the operational isolation that sharding is intended to provide.

This pattern can improve operational resiliency and change safety by containing the impact of record or link changes. It does not change the underlying availability commitment of the Azure DNS service.

## Hub-and-Spoke Considerations

Hub-and-spoke landing zones frequently place shared DNS capability in, or reachable from, the hub while workloads deploy in spoke virtual networks. DNS resolution must function from spokes and from any hybrid-connected network permitted to access services.

Virtual network links, routing, DNS server settings and firewall behavior need consistent design. A workload spoke should not need its own ad hoc DNS server simply because a private endpoint was created. Equally, central DNS services need sufficient availability and monitoring because a resolution outage can affect many products at once.

When workloads are segmented or have different regulatory boundaries, link and forwarding design should reflect those boundaries. Central service does not justify unnecessary cross-workload reachability.

## Azure DNS Private Resolver

Azure DNS Private Resolver provides managed inbound and outbound endpoints and forwarding rulesets for hybrid name-resolution patterns, reducing the need to operate custom DNS forwarder virtual machines for many scenarios.

An inbound endpoint enables connected networks to send DNS queries into Azure for names that Azure can resolve, including private zones exposed through the intended design. An outbound endpoint and forwarding rulesets allow Azure workloads to resolve specified domains through destinations such as enterprise DNS services.

The resolver belongs in the connectivity architecture: subnets, regional resilience, routing, forwarding rules, diagnostic needs and ownership must be planned. It is not merely a convenience feature added individually by each workload team.

> **Architecture takeaway:** Name resolution is an operational dependency; resolver resilience, monitoring and ownership belong in architecture decisions.

## Conditional Forwarding from On-Premises

Hybrid applications often require on-premises clients or servers to reach Azure services through private endpoints. Enterprise DNS servers can conditionally forward the appropriate Azure private-resolution queries toward Azure DNS Private Resolver inbound endpoints or another approved Azure resolution path.

The exact forwarding model must be documented and tested. Overly broad forwarding can create unexpected dependency or resolution behavior; incomplete forwarding creates intermittent failures depending on where clients operate. Include disaster recovery and secondary-region behavior in the design rather than addressing it only during an outage.

Operational troubleshooting should allow support teams to answer: which DNS server responded, which zone or rule applied, which private IP was returned and whether that IP is reachable from the requesting network.

## Product and Platform Ownership Model

Clear responsibility avoids both uncontrolled sprawl and slow manual delivery:

- The platform team owns DNS architecture, approved private endpoint patterns, central zones, resolver capability, forwarding policy and monitoring.
- Product teams own their services, data-access decisions, endpoint requests and validation of application connectivity.
- Security and governance teams define public-access restrictions, evidence expectations and exception review.
- Operations teams need runbooks for DNS resolution failures, endpoint lifecycle and regional recovery.

This model can be implemented through a documented module catalogue. A module request may include service type, environment, spoke network, DNS association and ownership metadata, then deploy the endpoint according to the approved platform pattern.

## Common failure modes

Frequent causes of trouble include:

- Product subscriptions creating duplicate private DNS zones for the same Azure service.
- Missing virtual-network links, causing Azure-hosted clients to receive public answers or no useful answer.
- On-premises DNS without the required conditional forwarders.
- Private endpoint creation separated from DNS record lifecycle.
- Stale records after endpoints are replaced or deleted.
- DNS designs that do not account for disaster recovery or regional failure.
- Troubleshooting processes that check firewall rules without confirming resolution first.

These failure modes are preventable when private DNS is treated as shared platform engineering.

## Governance and Naming

Governance should define which Azure services are expected to use private access, who can create endpoint resources, how public network access is constrained and how DNS associations are made. Azure Policy and infrastructure as code can help prevent unsupported patterns and collect compliance evidence.

Naming and metadata make operations easier. Endpoint resources, associated network interfaces and requests should identify product, environment, region, service owner and support contact where standards allow. DNS zones themselves usually follow Azure service conventions, so management metadata and deployment records are essential context.

Diagnostics should be included for resolver components and relevant networking controls. Review DNS patterns when introducing a new Private Link service type, a new region or a new hybrid-connectivity route.

## Architecture checklist

- Private endpoint and DNS provisioning are delivered as one supported pattern.
- Central zone ownership and subscription placement are defined.
- Spoke network resolution and segmentation requirements are documented.
- Hybrid conditional forwarding has been tested from intended source networks.
- Azure DNS Private Resolver architecture includes resilience and ownership.
- Public access restrictions align with private-resolution expectations.
- Automation controls record creation and cleanup.
- Monitoring and troubleshooting runbooks include DNS-first verification.
- Recovery-region and regulated-boundary considerations are explicit.

## Further reading

- [Azure Networking](/azure-networking/)
- [Azure Landing Zones](/azure-landing-zones/)
- [Azure DNS Private Resolver documentation](https://learn.microsoft.com/en-us/azure/dns/dns-private-resolver-overview)
- [Sharding private DNS zones - Azure DNS](https://learn.microsoft.com/en-us/azure/dns/sharding-private-dns-zones)

## Related architecture notes

- [Designing Azure Landing Zones for Product Teams]({% post_url 2026-05-25-designing-azure-landing-zones-for-product-teams %})
- [Infrastructure as Code](/infrastructure-as-code/)
- [Sovereign Cloud](/sovereign-cloud/)

## Summary

Private DNS at scale is a foundational Azure landing-zone capability. Central zones, governed private endpoint integration, managed resolution paths and clear product/platform ownership allow enterprises to use private Azure services consistently without turning every connection into a bespoke network project. When DNS is designed as part of the platform, secure connectivity becomes more reliable, observable and easier for product teams to consume.
