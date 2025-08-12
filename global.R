library(bs4Dash)
library(shiny)
library(shinyjs)
library(shinyWidgets)
library(DT)

# Get Composer URL from environment variable
renviron_path <- file.path(getwd(), ".Renviron")
if (!file.exists(renviron_path)) {
  stop("Could not find .Renviron file at: ", renviron_path, "\n",
       "Please create the file and set the OCA_COMPOSER_URL environment variable.")
}

readRenviron(renviron_path)
composer_url <- Sys.getenv("OCA_COMPOSER_URL")
if (composer_url == "") {
  stop("OCA_COMPOSER_URL environment variable is not set in .Renviron file.\n",
       "Please add the following line to ", renviron_path, ":\n",
       "OCA_COMPOSER_URL=[your-composer-url]")
}

# Load schema mapping from config file
schema_config <- jsonlite::fromJSON("config/schemas.json")

# Create dropdown choices from the mapping
schema_choices <- list()
for (file_id in names(schema_config)) {
  schema_choices[schema_config[[file_id]]$name] <- file_id
}