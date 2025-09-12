**Note**: This application is currently under active development. Features and functionality may change as development progresses.

# Shiny Verifier

A Shiny application for verifying data against predefined schemas using an embedded React-based verifier.

## Overview

The Shiny Verifier is a web application that allows users to:
- Select from predefined schema definitions
- Upload and verify data against the selected schema
- View verification results in an interactive interface
- Automatically save verified data with organized file structure

The application uses a modern UI built with `bs4Dash` and integrates with the [OCA Composer](https://github.com/agrifooddatacanada/OCA_Composer) for data verification. OCA (Overlays Capture Architecture) is an international open standard for writing data schemas, developed by the Human Colossus Foundation.

## Features

- Modern, responsive UI using bs4Dash
- Schema selection from predefined templates
- Real-time data verification
- Interactive verification results display
- Support for multiple data formats
- Integration with OCA Composer for schema verification
- Local data processing (data never leaves the user's computer)
- **Automatic file saving with organized folder structure**
- **ISO 8601 timestamp-based file naming**
- **Download functionality for verified data**

## File Organization

The application automatically saves verified data to a structured folder system:

### Folder Structure
```
upload_files/
├── 2025/
│   ├── 08/
│   │   ├── 2025-08-15T11-54-35Z_sensor_aggregation_scr.csv
│   │   └── 2025-08-15T12-00-00Z_sensor_health_scr.csv
│   └── 09/
└── 2026/
    └── 01/
```

### File Naming Convention
- **Format**: `YYYY-MM-DDTHH-MM-SSZ_table_name.csv`
- **Example**: `2025-08-15T11-54-35Z_sensor_aggregation_scr.csv`
- **Timestamp**: UTC timezone (ISO 8601 format)
- **Table Name**: Extracted from the JSON schema filename

### Features
- **Automatic Creation**: Year and month subdirectories are created automatically
- **UTC Timestamps**: All timestamps are in UTC for consistency
- **Clean Names**: Special characters are sanitized for filesystem compatibility
- **Organized Storage**: Files are automatically sorted by year and month

## Prerequisites

- R (version 4.0.0 or higher)
- RStudio (recommended)
- renv package manager

## Installation

1. Clone the repository:
```bash
git clone https://github.com/agrifooddatacanada/shiny_verifier.git
```

2. Restore the project dependencies using renv:
```R
# Install renv if not already installed
install.packages("renv")

# Restore the project environment
renv::restore()
```

3. Create a `.Renviron` file in the project root with the following content:
```
OCA_COMPOSER_URL=[your-oca-composer-url]
```

For example:
```
OCA_COMPOSER_URL=https://my-oca-composer-url.ca
```

Or, if running a dev instance of OCA Composer locally:
```
OCA_COMPOSER_URL=http://localhost:3000
```

Note: Only include the base URL in the `.Renviron` file. The `/oca-data-verifier` path is automatically appended in the application code.

## Usage

1. Start the application:
```R
shiny::runApp()
```

2. In the application:
   - Select a schema from the dropdown menu
   - Click "Start data verification" to begin verification
   - View verification results in the interactive interface
   - Verified data is automatically saved to the `upload_files` directory
   - Use the download button to get a copy of the verified data

## Development Status

This application is currently under active development. Features and functionality may change as development progresses.

The application is developed with support from Agri-food Data Canada, funded by CFREF through the Food from Thought grant held at the University of Guelph.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the European Union Public Licence (EUPL) v1.2. For more information, see the [EUPL-1.2 license file](LICENSE).

The EUPL is a copyleft license that allows for the free use, modification, and distribution of the software, with the requirement that any modifications or derivative works must also be licensed under the EUPL.
