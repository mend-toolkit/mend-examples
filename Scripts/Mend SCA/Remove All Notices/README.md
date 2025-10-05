# Mend Remove Library Notices Script

This bash script provides a simple interface to the Mend API for authentication and library notice management operations.


## Prerequisites

- **bash** (on Windows, use Git Bash, WSL, or Cygwin)
- **curl** - for API requests
- **jq** - for JSON parsing

### Installing jq

- **Ubuntu/Debian**: `sudo apt-get install jq`
- **CentOS/RHEL**: `sudo yum install jq` or `sudo dnf install jq`
- **macOS**: `brew install jq`

## Environment Variables

The script requires the following environment variables:

### Required Variables

- `MEND_EMAIL` - Your Mend account email address
- `MEND_USER_KEY` - Your Mend user key (personal access token)
- `MEND_ORG_TOKEN` - Organization UUID or API Key from Mend
- `MEND_PRODUCT` - The name of the product you want to work with

### Optional Variables

- `MEND_API_URL` - Mend API base URL (default: `https://api-saas.mend.io`)

## Usage

### Setting Up Environment Variables

```bash
export MEND_EMAIL="your-email@example.com"
export MEND_USER_KEY="your-user-key-here"
export MEND_ORG_TOKEN="your-org-token-or-uuid"
export MEND_PRODUCT="Your Product Name"
```

### Making the Script Executable (Linux/macOS)

On Linux and macOS systems, you can make the script executable to run it directly:

```bash
chmod +x mend_remove_library_notices.sh
```

### Running the Script

The script runs a single automated workflow. Simply execute:

**On Windows (using Git Bash or WSL):**
```bash
bash mend_remove_library_notices.sh
```

**On Linux/macOS (after making executable):**
```bash
./mend_remove_library_notices.sh
```

**On Linux/macOS (without making executable):**
```bash
bash mend_remove_library_notices.sh
```

## Example Workflow

```bash
# Set up environment variables
export MEND_EMAIL="john.doe@company.com"
export MEND_USER_KEY="abc123def456..."
export MEND_ORG_TOKEN="123e4567-e89b-12d3-a456-426655440000"
export MEND_PRODUCT="My Web Application"

# Run the script
bash mend_remove_library_notices.sh
```

The script will automatically:
1. Authenticate with the Mend API
2. Find your product by name
3. Retrieve all libraries for that product
4. Set notice text to null for each library


## API Endpoints Used

The script interacts with the following Mend API endpoints:

1. **Authentication**: `POST /api/v2.0/login`
2. **Products**: `GET /api/v2.0/orgs/{orgToken}/products`
3. **Libraries**: `GET /api/v2.0/products/{productToken}/libraries`
4. **Set Notice Text**: `POST /api/v2.0/products/{productToken}/libraries/{libraryUuid}/notices`

