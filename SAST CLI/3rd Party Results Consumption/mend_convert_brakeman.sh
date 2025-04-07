#!/bin/bash

# Check if input and output files are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <input_file> <output_file>"
    echo "Example: $0 results.json converted_results.json"
    exit 1
fi

# Define input and output files
INPUT_FILE="$1"
FINAL_OUTPUT="$2"

# Function to check if all required dependencies are installed
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is required but not installed. Please install jq first."
        echo "You can install it using: apt-get install jq (Debian/Ubuntu) or brew install jq (macOS)"
        exit 1
    fi
}

# Function to check if required files exist
check_files() {
    if [ ! -f "$INPUT_FILE" ]; then
        echo "Error: Input file '$INPUT_FILE' not found"
        exit 1
    fi
}

# Function to validate that all warnings have required fields
validate_warnings() {
    echo "Validating warnings..."
    
    # Get warnings without CWE IDs
    local warnings_without_cwe=$(jq '.warnings | map(select(.cwe_id == null or (.cwe_id | type == "array" and length == 0)))' "$INPUT_FILE")
    
    # Check if there are any warnings without CWE IDs
    if [ "$(echo "$warnings_without_cwe" | jq 'length')" -gt 0 ]; then
        echo "Error: Found warnings without CWE IDs:"
        echo "$warnings_without_cwe" | jq -r '.[] | "Warning type: \(.warning_type), File: \(.file), Line: \(.line)"'
        exit 1
    fi
    
    # Get warnings without check_name
    local warnings_without_check_name=$(jq '.warnings | map(select(.check_name == null or .check_name == ""))' "$INPUT_FILE")
    
    # Check if there are any warnings without check_name
    if [ "$(echo "$warnings_without_check_name" | jq 'length')" -gt 0 ]; then
        echo "Error: Found warnings without check_name:"
        echo "$warnings_without_check_name" | jq -r '.[] | "Warning type: \(.warning_type), File: \(.file), Line: \(.line)"'
        exit 1
    fi
    
    # Get warnings without warning_type
    local warnings_without_warning_type=$(jq '.warnings | map(select(.warning_type == null or .warning_type == ""))' "$INPUT_FILE")
    
    # Check if there are any warnings without warning_type
    if [ "$(echo "$warnings_without_warning_type" | jq 'length')" -gt 0 ]; then
        echo "Error: Found warnings without warning_type:"
        echo "$warnings_without_warning_type" | jq -r '.[] | "File: \(.file), Line: \(.line)"'
        exit 1
    fi
    
    echo "All warnings have required fields. Proceeding with conversion..."
}

# Function to get tool information
get_tool_info() {
    echo "Getting tool information..."
    JSON_OUTPUT=$(jq '{
        "tool": {
            "name": "Brakeman",
            "version": .scan_info.brakeman_version
        },
        "run": {
            "language": "Ruby",
            "findings": []
        }
    }' "$INPUT_FILE")
}

# Function to process a single warning
process_warning() {
    local warning_idx="$1"
    local input_file="$2"
    
    # Extract warning
    local warning_json=$(jq ".warnings[$warning_idx]" "$input_file")
    
    # Get CWE ID (we know it exists from validation)
    local cwe=$(echo "$warning_json" | jq -r '.cwe_id[0] | tostring')
    
    # Use default severity of "unknown"
    local severity="unknown"
    
    # Get check_name and warning_type early for progress message
    local check_name=$(echo "$warning_json" | jq -r '.check_name')
    local warning_type=$(echo "$warning_json" | jq -r '.warning_type')
    
    # Determine sink name
    local sink_name=$(echo "$warning_json" | jq -r '
        if .location and .location.method then
            if .location.class then
                .location.class + "." + .location.method
            elif .location.controller then
                .location.controller + "." + .location.method
            else
                "Unknown"
            end
        elif .location and .location.controller then
            .location.controller
        elif .check_name then
            .check_name
        else
            "Unknown"
        end
    ')
    
    # Get file and line
    local file=$(echo "$warning_json" | jq -r '.file // "Unknown"')
    local line=$(echo "$warning_json" | jq -r '.line // 1')
    
    # Create base finding JSON
    local finding=$(jq -n \
        --arg check_name "$check_name" \
        --arg warning_type "$warning_type" \
        --arg severity "$severity" \
        --arg description "$(echo "$warning_json" | jq -r '.message')" \
        --arg cwe "$cwe" \
        --arg sink_name "$sink_name" \
        --arg file "$file" \
        --argjson line "$line" \
        '{
            "type": {
                "name": ($check_name + " - " + $warning_type),
                "severity": $severity,
                "cwe": ($cwe | tonumber)
            },
            "description": $description,
            "sink": {
                "name": $sink_name,
                "file": $file,
                "line": $line
            }
        }')
    
    # Add flows if needed
    if echo "$warning_json" | jq -e '.user_input and .location' &>/dev/null; then
        local user_input=$(echo "$warning_json" | jq -r '.user_input // "user input"')
        finding=$(echo "$finding" | jq \
            --arg name "$user_input" \
            --arg file "$file" \
            --argjson line "$line" \
            '.flows = [{
                "name": $name,
                "file": $file,
                "line": $line
            }]')
    fi
    
    # Output progress message
    echo "Processed warning $((warning_idx + 1)): $check_name - $warning_type" >&2
    
    # Output the finding JSON
    echo "$finding"
}

# Export the process_warning function so it can be used by xargs
export -f process_warning

# Function to process warnings in parallel
process_warnings_parallel() {
    echo "Processing warnings in parallel..."
    
    # First get the number of warnings
    local num_warnings=$(jq '.warnings | length' "$INPUT_FILE")
    echo "Found $num_warnings warnings to process"
    
    # Calculate number of parallel processes (75% of CPU cores)
    local num_cores=$(nproc)
    local parallel_jobs=$(( (num_cores * 75 + 99) / 100 ))  # Round up to nearest integer
    
    # Process warnings in parallel using xargs and store findings in memory
    local findings=$(seq 0 $((num_warnings-1)) | xargs -P "$parallel_jobs" -I {} bash -c 'process_warning {} "$1"' _ "$INPUT_FILE" | jq -s '.')
    
    # Combine all findings into the JSON output
    JSON_OUTPUT=$(echo "$JSON_OUTPUT" | jq --argjson findings "$findings" '.run.findings = $findings')
}

# Function to finalize the output
finalize_output() {
    echo "Finalizing output..."
    echo "$JSON_OUTPUT" | jq '.' > "$FINAL_OUTPUT"
    echo "Conversion complete. Output saved to $FINAL_OUTPUT"
}

# Main function
main() {
    check_dependencies
    check_files
    validate_warnings
    get_tool_info
    process_warnings_parallel
    finalize_output
}

# Run the main function
main 