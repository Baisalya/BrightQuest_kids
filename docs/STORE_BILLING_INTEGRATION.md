# BrightQuest Kids Store Billing Boundary

Internal product IDs are `brightquest_class_3`, `brightquest_class_4` and `brightquest_class_5`. Each represents permanent one-time class access. Purchase and restore actions belong only to the parent-gated area.

The current repository contains a fail-closed store gateway and entitlement service. It intentionally cannot grant production ownership without a verified store/backend result. Locally persisted entitlement data is downgraded to cache-only evidence when read back and cannot unlock paid packs.

Before release, platform adapters must be implemented and tested against real Google Play one-time non-consumable products and Microsoft Store durable add-ons (or an approved signed licence path for non-Store Windows distribution). Pending, cancellation, refund/revocation, acknowledgement and restore flows must be verified in closed testing.

Android ownership does not automatically prove Windows ownership. Cross-platform sharing requires a secure parent account and backend verification; until then, restore is store-specific and the UI must say so clearly.
