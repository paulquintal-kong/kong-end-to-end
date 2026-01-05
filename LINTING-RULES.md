# FHIR API Linting Rules

This document describes the business rules enforced by the Spectral linting configuration for FHIR API implementations.

## Overview

The linting rules are designed to ensure:
- **Data Quality**: Required fields and proper data structures
- **Clinical Safety**: Critical information for patient care
- **Compliance**: Regulatory and standards compliance
- **Interoperability**: Consistent API behavior
- **Security**: Patient privacy and data protection
- **Performance**: Efficient API operations

## Setup

### Install Spectral CLI

```bash
npm install -g @stoplight/spectral-cli
```

### Run Linting

```bash
# Lint your FHIR API specification
spectral lint fhir-api.yaml

# Lint with custom ruleset
spectral lint fhir-api.yaml --ruleset .spectral.yaml

# Output to JSON for CI/CD integration
spectral lint fhir-api.yaml --format json
```

## Rule Categories

### 1. General FHIR Resource Rules

#### fhir-resource-id-required (ERROR)
All FHIR resources must have a unique identifier for tracking and referencing.

**Business Rationale**: Essential for resource versioning, auditing, and cross-referencing.

#### fhir-resource-meta-required (WARNING)
Resources should include metadata for versioning and audit trails.

**Business Rationale**: Required for compliance, version control, and change tracking.

---

### 2. Patient Resource Rules

#### patient-identifier-required (ERROR)
Patients must have at least one identifier (MRN, SSN, National ID).

**Business Rationale**: Critical for patient matching, preventing duplicate records, and cross-system identification.

#### patient-name-required (ERROR)
Patient must have a name.

**Business Rationale**: Essential for clinical workflows, patient identification, and communication.

#### patient-contact-info-required (WARNING)
Patient should have contact information (phone or email).

**Business Rationale**: Necessary for appointment reminders, test results, and emergency contact.

#### patient-gender-required (WARNING)
Patient gender should be recorded.

**Business Rationale**: Important for demographic analysis, population health, and gender-specific care protocols.

#### patient-birthdate-required (ERROR)
Patient birth date is required.

**Business Rationale**: Critical for age verification, pediatric/geriatric protocols, and medication dosing.

---

### 3. Observation Resource Rules

#### observation-subject-required (ERROR)
Observations must reference a patient or subject.

**Business Rationale**: Prevents orphaned clinical data and ensures results are associated with the correct patient.

#### observation-code-required (ERROR)
Observations must have standardized codes (LOINC preferred).

**Business Rationale**: Enables semantic interoperability, clinical decision support, and analytics.

#### observation-status-required (ERROR)
Observation status must be specified.

**Business Rationale**: Clinical safety - prevents acting on preliminary or cancelled results.

#### observation-effective-date-required (WARNING)
Observations should have an effective date.

**Business Rationale**: Essential for trending, comparing results over time, and clinical interpretation.

#### observation-performer-recommended (WARNING)
Observations should identify the performer.

**Business Rationale**: Accountability, quality assurance, and follow-up questions.

---

### 4. Encounter Resource Rules

#### encounter-subject-required (ERROR)
Encounters must reference a patient.

**Business Rationale**: Prevents billing errors and ensures proper care attribution.

#### encounter-class-required (ERROR)
Encounter class must be specified (inpatient, outpatient, emergency).

**Business Rationale**: Required for billing, resource planning, and quality metrics.

#### encounter-period-required (WARNING)
Encounters should have a period with start and end times.

**Business Rationale**: Length of stay metrics, billing, and capacity planning.

#### encounter-location-recommended (INFO)
Encounters should specify location.

**Business Rationale**: Care coordination, infection control, and resource utilization tracking.

---

### 5. Condition Resource Rules

#### condition-subject-required (ERROR)
Conditions must reference a patient.

**Business Rationale**: Critical for problem lists and clinical decision support.

#### condition-code-required (ERROR)
Conditions must have a coded diagnosis (ICD-10, SNOMED-CT).

**Business Rationale**: Required for billing, quality reporting, and population health.

#### condition-clinical-status-required (ERROR)
Condition clinical status must be specified.

**Business Rationale**: Distinguishes active problems from resolved ones - critical for care planning.

#### condition-onset-recommended (WARNING)
Conditions should have onset information.

**Business Rationale**: Important for disease progression tracking and chronic disease management.

---

### 6. Medication Resource Rules

#### medication-code-required (ERROR)
Medications must have standardized codes (RxNorm preferred).

**Business Rationale**: Drug-drug interaction checking, formulary management, and e-prescribing.

#### medication-form-recommended (WARNING)
Medication form should be specified.

**Business Rationale**: Prevents administration errors (e.g., oral vs. IV).

---

### 7. Security & Privacy Rules

#### api-security-defined (ERROR)
All endpoints must have security requirements defined.

**Business Rationale**: HIPAA compliance and patient privacy protection.

#### sensitive-data-encryption (ERROR)
Server URLs must use HTTPS.

**Business Rationale**: PHI protection in transit, regulatory compliance (HIPAA, GDPR).

---

### 8. Data Quality Rules

#### required-search-parameters (WARNING)
Resource searches should support multiple parameters.

**Business Rationale**: Enables efficient queries and reduces unnecessary data transfer.

#### pagination-support-required (ERROR)
Search operations must support pagination (_count, _offset).

**Business Rationale**: Performance, prevents timeout on large datasets, and memory management.

---

### 9. Interoperability Rules

#### standard-http-status-codes (ERROR)
APIs should define standard response codes (200, 400, 404, 500).

**Business Rationale**: Consistent error handling across systems and easier integration.

#### fhir-json-content-type (ERROR)
FHIR responses must support 'application/fhir+json'.

**Business Rationale**: FHIR specification compliance and tool compatibility.

---

### 10. Performance & Scalability Rules

#### response-size-limits (WARNING)
Search results should have default and maximum limits.

**Business Rationale**: Prevents performance degradation and DOS conditions.

---

### 11. Audit & Compliance Rules

#### operation-descriptions-required (WARNING)
All operations must have descriptions.

**Business Rationale**: Documentation for auditors, developers, and compliance reviews.

#### operation-ids-required (ERROR)
Each operation must have a unique operationId.

**Business Rationale**: Enables request tracking, audit logging, and analytics.

---

## Severity Levels

- **ERROR**: Must be fixed before production deployment
- **WARNING**: Should be fixed for best practices
- **INFO**: Recommendations for optimization

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: FHIR API Linting
on: [push, pull_request]
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Spectral
        run: npm install -g @stoplight/spectral-cli
      - name: Lint FHIR API
        run: spectral lint fhir-api.yaml --ruleset .spectral.yaml --format junit --output spectral-report.xml
      - name: Publish Results
        uses: EnricoMi/publish-unit-test-result-action@v2
        if: always()
        with:
          files: spectral-report.xml
```

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit
spectral lint fhir-api.yaml --ruleset .spectral.yaml --fail-severity error
```

## Customization

To customize rules for your organization:

1. Edit `.spectral.yaml`
2. Adjust severity levels based on your requirements
3. Add organization-specific rules
4. Document custom rules in this file

## References

- [FHIR Specification](https://hl7.org/fhir/)
- [Spectral Documentation](https://meta.stoplight.io/docs/spectral/)
- [HIPAA Security Rule](https://www.hhs.gov/hipaa/for-professionals/security/)
- [HL7 FHIR Implementation Guide](https://www.hl7.org/fhir/implementationguide.html)
