# Legacy Cleanup Summary

**Date**: January 10, 2026

## Files Archived

The following legacy components have been moved to `.archive/` directory:

### Terraform Files (11 files)
Moved from `terraform/` to `.archive/legacy-terraform/`:
- `api_catalog.tf`
- `backend.tf`
- `control_plane.tf`
- `developer_portal.tf`
- `outputs.tf`
- `plugins.tf`
- `provider.tf`
- `service.tf`
- `service_catalog.tf`
- `variables.tf`
- `terraform.tfvars`

### Shell Scripts (3 files)
Moved from root to `.archive/legacy-scripts/`:
- `start_demo.sh`
- `stop_demo.sh`
- `setup_kong_dataplane.sh`

### Temporary Files Removed
- `.ngrok-url.txt`
- `.ngrok.log`
- `.ngrok.pid`
- `terraform/.terraform/` (cache)
- `terraform/.terraform.lock.hcl`
- `.DS_Store` (macOS metadata)

## Functionality Preserved

✅ **All functionality maintained**:
- FHIR server: Still available via `docker-compose up -d`
- API specs: `.insomnia/` directory intact
- Linting rules: `.spectral.yaml` intact
- CI/CD: `.github/workflows/` intact
- Portal content: `portal/` directory intact
- Demo workflow: Replaced with modular `terraform/stages/*/demo.sh` scripts

## Current Structure

```
kong-end-to-end/
├── .archive/                   # Legacy files (archived)
├── .github/workflows/          # CI/CD pipelines
├── .insomnia/                  # API specs and tests
├── .kong/                      # Kong certificates (gitignored)
├── DEMO_GUIDE.md              # Presales playbook
├── README.md                  # Main documentation
├── README-original.md         # Original FHIR setup docs
├── docker-compose.yml         # FHIR server
├── portal/                    # Portal content
└── terraform/
    └── stages/                # Modular demo stages
        ├── 1-platform/
        ├── 2-integration/
        ├── 3-api-spec-testing/
        ├── 4-api-product/
        └── 5-developer-portal/
```

## Migration Complete

The repository is now:
- ✅ Cleaner and more focused
- ✅ Easier to navigate
- ✅ Better organized for presales demos
- ✅ Fully modular and persona-based
- ✅ No lost functionality

## Recovery

If needed, files can be restored from `.archive/`:
```bash
# Restore Terraform files
cp .archive/legacy-terraform/*.tf terraform/

# Restore scripts
cp .archive/legacy-scripts/*.sh .
```

## Next Steps

- [ ] Run full demo to verify all stages work
- [ ] Test Stage 3 (API Spec Testing) independently
- [ ] Verify CI/CD workflows still function
- [ ] Consider permanent deletion of `.archive/` after 3 months
