# Patient Records API Developer Portal

## Portal Information

- **Portal ID**: `519551c7-565e-4031-bd8e-8e5d50af25f2`
- **Portal Name**: Patient Records API
- **Display Name**: Developer Portal
- **Portal URL**: https://d89b009b6d6e.au.kongportals.com
- **Region**: AU (Australia)
- **Version**: V3 (Modern Portal)

## Portal Configuration

### Access Settings
- **Authentication Enabled**: No (portal is publicly accessible)
- **RBAC Enabled**: No
- **Auto-approve Developers**: No
- **Auto-approve Applications**: No

### Visibility Settings
- **Default API Visibility**: Public
- **Default Page Visibility**: Public

## Portal Structure

### Pages (5 total, 7 including children)

The portal includes the following page structure:

```
/ (Kong API)
  ├─ Description: "Start building and innovating with our APIs"
  └─ Status: Published, Public

/apis (APIs)
  ├─ Description: "Explore a wide range of API products in our Developer Portal designed for fast, flexible development."
  └─ Status: Published, Public

/getting-started (Getting started)
  ├─ Description: "Get started with our new Developer Portal!"
  └─ Status: Published, Public

/guides (Guides)
  ├─ Description: "Step-by-step guides to help you build, integrate, and optimize with our platform."
  ├─ Status: Published, Public
  └─ Children:
      ├─ /document-apis (Document APIs)
      │   ├─ Description: "Discover best practices, tools, and examples to help developers understand and use your APIs"
      │   └─ Status: Published, Public
      │
      └─ /publish-apis (Publish APIs)
          ├─ Description: "Learn best practices for exposing, versioning, and managing your APIs"
          ├─ Status: Published, Public
          └─ Children:
              └─ /versioning (API Versioning)
                  ├─ Description: "Learn best practices for API versioning to manage changes"
                  └─ Status: Published, Public
```

### Page Details

All pages are stored in [portal-pages.json](./portal-pages.json) with the following structure:

```json
{
  "id": "unique-page-id",
  "slug": "/page-path",
  "title": "Page Title",
  "visibility": "public",
  "status": "published",
  "description": "Page description",
  "parent_page_id": "parent-id-or-null",
  "created_at": "timestamp",
  "updated_at": "timestamp",
  "children": []
}
```

## Terraform Management

The portal is now managed via Terraform using the configuration in:
- [../terraform/developer_portal.tf](../terraform/developer_portal.tf)

### Importing the Portal

The portal was imported into Terraform state using:

```bash
terraform import konnect_portal.patient_records_portal 519551c7-565e-4031-bd8e-8e5d50af25f2
```

### Managing Pages

To manage individual portal pages in Terraform, you can use the `konnect_portal_page` resource. Example:

```hcl
resource "konnect_portal_page" "home" {
  portal_id       = konnect_portal.patient_records_portal.id
  slug            = "/"
  title           = "Kong API"
  status          = "published"
  visibility      = "public"
  description     = "Start building and innovating with our APIs"
  content         = file("${path.module}/../portal/pages/home.md")
  content_type    = "markdown"
}
```

## API Products & Publishing

**Note**: Currently, the Patient Records API is managed as a **Catalog API** (using `konnect_api` resource), which is separate from the **API Products** model used by Developer Portals.

To publish APIs to the Developer Portal, you need to:

1. Create an **API Product** using `konnect_api_product` resource
2. Create a **Product Version** for the API Product
3. Link it to the portal using `konnect_portal_product_version`

### API Endpoints Discovery

During the download process, we discovered the following v3 API endpoints:

✅ **Working endpoints**:
- `GET /v3/portals/{portal_id}` - Get portal configuration
- `GET /v3/portals/{portal_id}/pages` - List all portal pages

❌ **Non-working endpoints** (404 errors):
- `/v3/portals/{portal_id}/product-versions`
- `/v3/portals/{portal_id}/api-products`
- `/v3/portals/{portal_id}/api-product-versions`
- `/v3/portal-pages?filter[portal_id]={id}` (filter query param approach)
- `/v3/portal-product-versions?filter[portal_id]={id}`

## Downloaded Files

- `portal-config.json` - Full portal configuration
- `portal-pages.json` - All portal pages with hierarchy
- `README.md` - This file (portal documentation)

## Next Steps

To fully manage this portal in Terraform:

1. ✅ Portal base configuration imported and managed
2. ⏳ Create `konnect_portal_page` resources for each page (optional)
3. ⏳ Create API Product for Patient Records API (required to publish to portal)
4. ⏳ Link API Product to portal using `konnect_portal_product_version`
5. ⏳ Configure authentication strategies if needed
6. ⏳ Set up custom domain if desired

## References

- [Kong Konnect Portal Documentation](https://docs.konghq.com/konnect/dev-portal/)
- [Terraform Provider Documentation](https://registry.terraform.io/providers/Kong/konnect/latest/docs/resources/portal)
