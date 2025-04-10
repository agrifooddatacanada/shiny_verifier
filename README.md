**Note**: This application is currently under active development. Features and functionality may change as development progresses.

# Shiny Verifier

A Shiny application for verifying data against predefined schemas using an embedded React-based verifier.

## Overview

The Shiny Verifier is a web application that allows users to:
- Select from predefined schema definitions
- Upload and verify data against the selected schema
- View verification results in an interactive interface

The application uses a modern UI built with `bs4Dash` and integrates with the [OCA Composer](https://github.com/agrifooddatacanada/OCA_Composer/tree/white_label) for data verification. OCA (Overlays Capture Architecture) is an international open standard for writing data schemas, developed by the Human Colossus Foundation.

## Features

- Modern, responsive UI using bs4Dash
- Schema selection from predefined templates
- Real-time data verification
- Interactive verification results display
- Support for multiple data formats
- Integration with OCA Composer for schema verification
- Local data processing (data never leaves the user's computer)

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
OCA_COMPOSER_URL=[your-composer-url]
```
Note: Only include the base URL in the `.Renviron` file. The `/oca-data-validator` path is automatically appended in the application code.

## Usage

1. Start the application:
```R
shiny::runApp()
```

2. In the application:
   - Select a schema from the dropdown menu
   - Click "Submit" to begin verification
   - View verification results in the interactive interface

## Development Status

This application is currently under active development. Features and functionality may change as development progresses.

The application is developed with support from Agri-food Data Canada, funded by CFREF through the Food from Thought grant held at the University of Guelph.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the European Union Public Licence (EUPL) v1.2. For more information, see the [EUPL-1.2 license file](LICENSE).

The EUPL is a copyleft license that allows for the free use, modification, and distribution of the software, with the requirement that any modifications or derivative works must also be licensed under the EUPL.
