# library(bs4Dash)
# library(shiny)
# library(shinyjs)
# library(shinyWidgets)
# 
# # Load schema config to create `schema_choices` (this also needs to be in both files if used in UI)
# schema_config <- jsonlite::fromJSON("config/schemas.json")
# schema_choices <- list()
# for (file_id in names(schema_config)) {
#   schema_choices[schema_config[[file_id]]$name] <- file_id
# }
# 
# dashboardPage(
#   title = "Shiny Verifier",
#   skin = "danger",
#   scrollToTop = T,
#   fullscreen = T,
#   help = NULL,
#   dark = NULL,
#   
#   dashboardHeader(
#     title = div(
#       style = "margin-left: 50px; padding: 12px 0;",
#       tags$i("Version: 0.1")
#     ),
#     status = "white",
#     div(style = "text-align: center;",
#         tags$b("Shiny Verifier")
#     )
#   ),
#   
#   dashboardSidebar(
#     collapsed = T,
#     minified = F,
#     elevation = 1,
#     fixed = F,
#     skin = "danger",
#     status = "danger",
#     sidebarMenu(
#       menuItem(
#         "Upload",
#         tabName = "app",
#         icon = icon("upload")
#       )
#     )
#   ),
#   
#   dashboardBody(
#     useShinyjs(),
#     tags$style(".nav-pills .nav-link.active {color: #fff; background-color: #dc3545;}"),
#     
#     tags$script(HTML("
#     
#       Shiny.addCustomMessageHandler('json2iframe', function(message) {
#         try {
#           var iframe_id = 'OCA_Composer_iframe';
#           var iframe = document.getElementById(iframe_id);
#           if (iframe && iframe.contentWindow) {
#             iframe.src = iframe.src;
#             iframe.onload = function() {
#               try {
#                 setTimeout(function() {
#                   try {
#                     iframe.contentWindow.postMessage(
#                       {
#                         type: 'JSON_SCHEMA',
#                         data: message.data
#                       },
#                       '*'
#                     );
#                   } catch (postMessageError) {
#                     console.error('Error sending postMessage:', postMessageError)
#                   }
#                 }, 1000);
#               } catch (onloadError) {
#                 console.error('Error in onload handler:', onloadError)
#               }
#             };
#           } else {
#             console.error('iframe or iframe.contentWindow not found. iframe_id:', iframe_id)
#           }
#         } catch (error) {
#           console.error('Error in json2iframe handler:', error)
#         }
#       });
#     ")),
#     
#     tabItems(
#       tabItem(
#         tabName = "app",
#         tagList(
#           column(12,
#                  fluidRow(
#                    column(12,
#                           img(src = "UoG_logo.png", height = "80px", align = "left", style = "margin-top: 10px;"),
#                           img(src = "FOFR1002_ADC_Logo_Colour_Short.png", height = "100px", align = "right")
#                    )
#                  )
#           ),
#           br(),
#           fluidRow(
#             column(12,
#                    box(
#                      title = tagList(icon("upload"), "Upload"),
#                      width = 12,
#                      collapsible = T,
#                      elevation = 2,
#                      solidHeader = F,
#                      status = "danger",
#                      p("Disclaimer placeholder will go here"),
#                      selectInput("schema_choice", "Select a target table", choices = schema_choices),
#                      actionButton("submit_schema", "Start data verification")
#                    )
#             )
#           ),
#           fluidRow(
#             column(12,
#                    div(id = "hidden_iframe",
#                        box(
#                          title = tagList(icon("check-double"), "Verify"),
#                          width = 12,
#                          collapsible = F,
#                          elevation = 2,
#                          maximizable = T,
#                          solidHeader = F,
#                          status = "danger",
#                          tags$iframe(
#                            id = "OCA_Composer_iframe",
#                            src = paste0(Sys.getenv("OCA_COMPOSER_URL"), "/oca-data-validator"),
#                            height = "1200px",
#                            width = "100%",
#                            style = "border: none; border-radius: 10px; overflow: hidden; background-color: white;"
#                          )
#                        )
#                    )
#             )
#           )
#         )
#       )
#     )
#   )
# )
