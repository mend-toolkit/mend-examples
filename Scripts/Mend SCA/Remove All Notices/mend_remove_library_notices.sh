#!/bin/bash

# Mend API Integration Script
# This script authenticates with Mend API and performs library operations

# set -e  # Exit on any error - commented out for debugging

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to validate required environment variables
validate_env_vars() {
    log_info "Validating environment variables..."
    
    local required_vars=("MEND_EMAIL" "MEND_USER_KEY" "MEND_ORG_TOKEN" "MEND_PRODUCT")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -ne 0 ]]; then
        log_error "Missing required environment variables:"
        for var in "${missing_vars[@]}"; do
            echo "  - $var"
        done
        echo
        echo "Required environment variables:"
        echo "  MEND_EMAIL      - Your Mend account email"
        echo "  MEND_USER_KEY   - Your Mend user key (personal access token)"
        echo "  MEND_ORG_TOKEN  - Organization UUID or API Key"
        echo "  MEND_PRODUCT    - Product name to filter for"
        echo
        echo "Optional environment variables:"
        echo "  MEND_API_URL    - Mend API base URL (default: https://api-saas.mend.io)"
        exit 1
    fi
    
    log_success "All required environment variables are set"
}

# Function to authenticate and get JWT token
mend_login() {
    log_info "Authenticating with Mend API..."
    
    local api_url="${MEND_API_URL:-https://api-saas.mend.io}"
    local login_payload=$(cat <<EOF
{
    "email": "${MEND_EMAIL}",
    "orgToken": "${MEND_ORG_TOKEN}",
    "userKey": "${MEND_USER_KEY}"
}
EOF
)
    
    local response
    response=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        -d "$login_payload" \
        "${api_url}/api/v2.0/login")
    
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | head -n -1)
    
    if [[ "$http_code" != "200" ]]; then
        log_error "Authentication failed with HTTP code: $http_code"
        echo "Response: $body"
        exit 1
    fi
    
    # Extract JWT token from response
    JWT_TOKEN=$(echo "$body" | jq -r '.retVal.jwtToken // empty')
    ORG_UUID=$(echo "$body" | jq -r '.retVal.orgUuid // empty')
    ORG_NAME=$(echo "$body" | jq -r '.retVal.orgName // empty')
    
    if [[ -z "$JWT_TOKEN" ]]; then
        log_error "Failed to extract JWT token from login response"
        echo "Response: $body"
        exit 1
    fi
    
    log_success "Successfully authenticated with Mend API"
    log_info "Organization: $ORG_NAME ($ORG_UUID)"
}

# Function to get all products and find the specified product UUID
get_product_uuid() {
    log_info "Retrieving products and searching for: $MEND_PRODUCT"
    
    local api_url="${MEND_API_URL:-https://api-saas.mend.io}"
    local response
    response=$(curl -s -w "\n%{http_code}" \
        -X GET \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $JWT_TOKEN" \
        "${api_url}/api/v2.0/orgs/${ORG_UUID}/products")
    
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | head -n -1)
    
    if [[ "$http_code" != "200" ]]; then
        log_error "Failed to retrieve products with HTTP code: $http_code"
        echo "Response: $body"
        exit 1
    fi
    
    # Find product UUID by name
    PRODUCT_UUID=$(echo "$body" | jq -r --arg product_name "$MEND_PRODUCT" '.retVal[] | select(.name == $product_name) | .uuid // empty')
    
    if [[ -z "$PRODUCT_UUID" ]]; then
        log_error "Product '$MEND_PRODUCT' not found"
        log_info "Available products:"
        echo "$body" | jq -r '.retVal[]? | "  - \(.name) (\(.uuid))"' || echo "  No products found or invalid response format"
        exit 1
    fi
    
    log_success "Found product '$MEND_PRODUCT' with UUID: $PRODUCT_UUID"
}

# Function to get libraries for the product
get_product_libraries() {
    log_info "Retrieving libraries for product: $MEND_PRODUCT"
    
    local api_url="${MEND_API_URL:-https://api-saas.mend.io}"
    local response
    response=$(curl -s -w "\n%{http_code}" \
        -X GET \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $JWT_TOKEN" \
        "${api_url}/api/v2.0/products/${PRODUCT_UUID}/libraries")
    
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | head -n -1)
    
    if [[ "$http_code" != "200" ]]; then
        log_error "Failed to retrieve libraries with HTTP code: $http_code"
        echo "Response: $body"
        exit 1
    fi
    
    # Store libraries response for further processing
    LIBRARIES_RESPONSE="$body"
    local library_count=$(echo "$body" | jq '.retVal | length // 0')
    
    log_success "Retrieved $library_count libraries for product '$MEND_PRODUCT'"
    
    # Display first few libraries as sample
    if [[ "$library_count" -gt 0 ]]; then
        log_info "Sample libraries:"
        echo "$body" | jq -r '.retVal[0:3][]? | "  - \(.name // .artifactId // "Unknown") (\(.uuid))"' || log_warning "Could not parse library names"
    fi
}

# Function to set library notice text to null for a specific library
set_library_notice_null() {
    local library_uuid="$1"
    local library_name="$2"
    
    log_info "Setting notice text to null for library: ${library_name:-$library_uuid}"
    
    local api_url="${MEND_API_URL:-https://api-saas.mend.io}"
    local payload='{"text": null}'
    
    local response
    response=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $JWT_TOKEN" \
        -d "$payload" \
        "${api_url}/api/v2.0/products/${PRODUCT_UUID}/libraries/${library_uuid}/notices")
    
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | head -n -1)
    
    if [[ "$http_code" != "200" ]]; then
        log_warning "Failed to set notice text to null for library $library_uuid with HTTP code: $http_code"
        echo "Response: $body"
        return 1
    fi
}

# Function to process all libraries and set their notice text to null
process_all_libraries() {
    log_info "Processing all libraries to set notice text to null..."
    
    if [[ -z "$LIBRARIES_RESPONSE" ]]; then
        log_error "No libraries data available. Run get_product_libraries first."
        return 1
    fi
    
    local library_count=$(echo "$LIBRARIES_RESPONSE" | jq '.retVal | length // 0')
    
    if [[ "$library_count" -eq 0 ]]; then
        log_warning "No libraries found for product '$MEND_PRODUCT'"
        return 0
    fi
    
    log_info "Processing $library_count libraries..."
    
    # Process each library
    local processed=0
    local failed=0
    
    # Use here-string to avoid subshell issues
    while IFS='|' read -r uuid name; do
        ((processed++))
        log_info "Processing library $processed/$library_count: $name"
        
        if set_library_notice_null "$uuid" "$name"; then
            log_success "Successfully updated notice for library: $name"
        else
            ((failed++))
            log_error "Failed to set notice text to null for library: $name (UUID: $uuid)"
        fi
        
        # Add small delay to avoid rate limiting
        sleep 0.5
    done <<< "$(echo "$LIBRARIES_RESPONSE" | jq -r '.retVal[] | "\(.uuid)|\(.name // .artifactId // "Unknown")"')"
    
    log_success "Completed processing libraries."
    log_info "Processed: $processed, Failed: $failed"
}

# Main script logic
main() {
    log_info "Starting Mend API integration script..."
    
    validate_env_vars
    mend_login
    get_product_uuid
    get_product_libraries
    process_all_libraries
    
    log_success "Mend API integration completed successfully!"
}

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    log_error "jq is required but not installed. Please install jq to run this script."
    echo "On Ubuntu/Debian: sudo apt-get install jq"
    echo "On CentOS/RHEL: sudo yum install jq"
    echo "On macOS: brew install jq"
    exit 1
fi

# Run main function with all arguments
main