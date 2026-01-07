#!/bin/bash

# Script to disable OAuth2 authentication in Insomnia workspace file
# This prevents OAuth2 errors in GitHub Actions CI/CD

WORKSPACE_FILE="FHIR API for Patient, Observation, Encounter, Condition, and Medication (Smile CDR Compatible) 1.0.1-wrk_8482e43ebd4e4c63923f4f78a48863ce.yaml"

echo "Disabling OAuth2 authentication in all requests..."

# Create backup
cp "$WORKSPACE_FILE" "${WORKSPACE_FILE}.backup"

# Replace all OAuth2 authentication blocks with no authentication
# This changes:
#   authentication:
#     type: oauth2
#     disabled: true
# To:
#   authentication:
#     type: none

sed -i.tmp '/authentication:/,/redirectUrl:/ {
  /authentication:/!{
    /type: oauth2/!{
      /disabled:/!{
        /grantType:/!{
          /accessTokenUrl:/!{
            /authorizationUrl:/!{
              /clientId:/!{
                /clientSecret:/!{
                  /scope:/!{
                    /redirectUrl:/!d
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}' "$WORKSPACE_FILE"

# Now replace the authentication type
sed -i.tmp 's/type: oauth2/type: none/' "$WORKSPACE_FILE"
sed -i.tmp '/disabled: true/d' "$WORKSPACE_FILE"

# Clean up temp files
rm -f "${WORKSPACE_FILE}.tmp"

echo "✅ OAuth2 authentication disabled in all requests"
echo "📄 Backup saved to: ${WORKSPACE_FILE}.backup"
echo ""
echo "To verify, run:"
echo "  grep -A5 'authentication:' '$WORKSPACE_FILE' | head -20"
