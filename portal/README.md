# Developer Portal Management Guide

> Documentation for managing the Kong Konnect v3 Developer Portal via Terraform

## Portal Overview

| Property | Value |
|----------|-------|
| **Portal ID** | `519551c7-565e-4031-bd8e-8e5d50af25f2` |
| **Name** | Patient Records API |
| **Display Name** | Developer Portal |
| **URL** | https://d89b009b6d6e.au.kongportals.com |
| **Region** | AU (Australia) |
| **Version** | V3 (Modern Portal) |

## Current Configuration

### Access Control
- **Authentication**: Disabled (public access)
- **RBAC**: Disabled
- **Developer Approval**: Manual approval required
- **Application Approval**: Manual approval required

### Visibility
- **APIs**: Public by default
- **Pages**: Public by default

## Portal Content

### Page Structure

The portal contains **7 pages** organized hierarchically:

```
/ (Home)
├── /apis (API Catalog)
├── /getting-started (Getting Started Guide)
└── /guides (Developer Guides)
    ├── /document-apis (Documentation Best Practices)
    └── /publish-apis (Publishing APIs)
        └── /versioning (API Versioning Guide)
```

All pages are **published** and **publicly visible**.

### Content Files

- **[portal-pages.json](portal-pages.json)** - Complete page metadata and hierarchy
- **[portal-config.json](portal-config.json)** - Portal configuration backup


---

## Terraform Management

The portal is managed via Terraform in `../terraform/developer_portal.tf`.

### Import Existing Portal

```bash
cd ../terraform
terraform import konnect_portal.patient_records_portal 519551c7-565e-4031-bd8e-8e5d50af25f2
```

### Portal Configuration

```hcl
resource "konnect_portal" "patient_records_portal" {
  name                      = "Patient Records API"
  display_name              = "Developer Portal"
  authentication_enabled    = false
  rbac_enabled             = false
  auto_approve_developers  = false
  auto_approve_applications = false
  default_api_visibility   = "public"
  default_page_visibility  = "public"
  
  labels = {
    environment = "production"
    api_type    = "fhir"
    team        = "healthcare"
  }
}
```

### Managing Portal Pages

To manage individual pages via Terraform:

```hcl
resource "konnect_portal_page" "getting_started" {
  portal_id    = konnect_portal.patient_records_portal.id
  slug         = "/getting-started"
  title        = "Getting Started"
  status       = "published"
  visibility   = "public"
  description  = "Get started with our API"
  content      = file("${path.module}/portal/pages/getting-started.md")
  content_type = "markdown"
}
```

---

## Publishing APIs to the Portal

The Patient Records API is managed as a **Catalog API** (using `konnect_api` resource). To publish APIs to the Developer Portal, you need to create an **API Product**.

### Steps to Publish

1. **Create API Product**

```hcl
resource "konnect_api_product" "fhir_patient_product" {
  name        = "Patient Records API"
  description = "FHIR R4 API for patient record management"
  
  version {
    name               = "1.0.0"
    gateway_service_id = konnect_gateway_service.fhir_patient_service.id
  }
}
```

2. **Link to Portal**

```hcl
resource "konnect_portal_product_version" "publish" {
  portal_id                        = konnect_portal.patient_records_portal.id
  product_version_id               = konnect_api_product.fhir_patient_product.version[0].id
  publish_status                   = "published"
  application_registration_enabled = true
  auto_approve_registration        = false
  deprecated                       = false
  auth_strategy_ids                = []
}
```

---

## API Endpoints

### Portal Management (V3 API)

| Operation | Endpoint | Method |
|-----------|----------|--------|
| Get portal config | `/v3/portals/{portal_id}` | GET |
| List portal pages | `/v3/portals/{portal_id}/pages` | GET |
| Update portal | `/v3/portals/{portal_id}` | PATCH |

**Note**: V3 portals use different endpoints than V2. Nested routes like `/v3/portals/{id}/portal-pages` return 404.

### Working Endpoints

```bash
# Get portal configuration
curl "https://au.api.konghq.com/v3/portals/519551c7-565e-4031-bd8e-8e5d50af25f2" \
  -H "Authorization: Bearer $KONNECT_TOKEN"

# List all pages
curl "https://au.api.konghq.com/v3/portals/519551c7-565e-4031-bd8e-8e5d50af25f2/pages" \
  -H "Authorization: Bearer $KONNECT_TOKEN"
```

---

## Next Steps

To fully manage this portal via Terraform:

- [x] Portal base configuration imported and managed
- [ ] Create `konnect_portal_page` resources for each page (optional)
- [ ] Create API Product for Patient Records API (required to publish)
- [ ] Link API Product using `konnect_portal_product_version`
- [ ] Configure authentication strategies (optional)
- [ ] Set up custom domain (optional)

---

## Resources

- [Kong Developer Portal Documentation](https://docs.konghq.com/konnect/dev-portal/)
- [Terraform Konnect Provider](https://registry.terraform.io/providers/Kong/konnect/latest/docs/resources/portal)
- [Kong API Products Guide](https://docs.konghq.com/konnect/api-products/)
