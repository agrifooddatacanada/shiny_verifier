# library(shiny)
# library(shinyjs)
# 
# # Load schema config
# schema_config <- jsonlite::fromJSON("config/schemas.json")
# 
# # Validate OCA_COMPOSER_URL
# renviron_path <- file.path(getwd(), ".Renviron")
# if (!file.exists(renviron_path)) {
#   stop("Could not find .Renviron file at: ", renviron_path, "\n",
#        "Please create the file and set the OCA_COMPOSER_URL environment variable.")
# }
# readRenviron(renviron_path)
# composer_url <- Sys.getenv("OCA_COMPOSER_URL")
# if (composer_url == "") {
#   stop("OCA_COMPOSER_URL environment variable is not set in .Renviron file.\n",
#        "Please add the following line to ", renviron_path, ":\n",
#        "OCA_COMPOSER_URL=[your-composer-url]")
# }
# 
# function(input, output, session) {
#   
#   observeEvent(input$submit_schema, {
#     req(input$schema_choice)
#     
#     shinyjs::show("hidden_iframe", anim = T, animType = 'slide')
#     
#     selected_file_id <- input$schema_choice
#     schema_path <- schema_config[[selected_file_id]]$path
#     json_file <- jsonlite::fromJSON(schema_path)
#     
#     session$sendCustomMessage(
#       type = "json2iframe",
#       message = list(
#         type = "JSON_SCHEMA",
#         data = json_file
#       )
#     )
#   })
#   
#   observeEvent(input$validated_data, {
#     # Handle validated data (optional)
#   })
# }
