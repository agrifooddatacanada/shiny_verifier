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

ui <- dashboardPage(
  title = "Shiny Verifier",
  skin = "danger",
  scrollToTop = T,
  fullscreen = T,
  help = NULL,
  dark = NULL,
  
  dashboardHeader(
    title = div(
      style = "margin-left: 50px; padding: 12px 0;",
      tags$i("Version: 0.1")
    ),
    status = "white",
    div(style = "text-align: center;",
        tags$b("Shiny Verifier")
    )
  ),
  
  dashboardSidebar(
    collapsed = T,
    minified = F,
    elevation = 1,
    fixed = F,
    skin = "danger",
    status = "danger",
    sidebarMenu(
      menuItem(
        "Upload",
        tabName = "app",
        icon = icon("upload")
      )
    )
  ),
  
  dashboardBody(
    # Activate ShinyJS library
    useShinyjs(),
    tags$style(".nav-pills .nav-link.active {color: #fff; background-color: #dc3545;}"),
    
    tags$script(
      HTML("
      // message listener for receiving data from iframe
      
      window.addEventListener('message', function(event) {
        // Check the origin of the message for security
      	if (
                event.origin === 'http://localhost:3000' ||
                event.origin === 'https://www.semanticengine.org'
              ) {
                // allowed origins, do nothing
              } else {
                console.log('Message from unknown origin:', event.origin);
                return;
              }
        // Check the type of the message if this is verified data from the validator
        if (event.data && event.data.type === 'VERIFIED_DATA') {
          console.log('Received verified data:', event.data.data);
          // Send the verified data back to Shiny
          Shiny.setInputValue('validated_data', event.data.data, {priority: 'event'});
        }
      });
      
      Shiny.addCustomMessageHandler('json2iframe', function(message) {
        try {
          var iframe_id = 'OCA_Composer_iframe';
          var iframe = document.getElementById(iframe_id);
          if (iframe && iframe.contentWindow) {
            // Reload the iframe first
            console.log('shiny: reloading iframe. iframe_id:', iframe_id, 'iframe.src:', iframe.src)
            iframe.src = iframe.src;
            
            // Wait for iframe to reload, then send the message
            iframe.onload = function() {
              try {
                console.log('shiny: sending schema. message:', message)
                setTimeout(function() {
                  try {
                    iframe.contentWindow.postMessage(
                      {
                        type: 'JSON_SCHEMA',
                        data: message.data
                      },
                      '*'
                    );
                    console.log('shiny: schema sent')
                  } catch (postMessageError) {
                    console.error('shiny: Error sending postMessage:', postMessageError)
                  }
                }, 1000); // Wait 1 second for iframe to fully load
              } catch (onloadError) {
                console.error('shiny: Error in onload handler:', onloadError)
              }
            };
          } else {
            console.error('shiny: iframe or iframe.contentWindow not found. iframe_id provided:', iframe_id)
          }
        } catch (error) {
          console.error('shiny: Error in json2iframe handler:', error)
        }
      });
    ")
    ),
    
    tabItems(
      tabItem(
        tabName = "app",
        
        tagList(
          column(12,
                 fluidRow(
                   column(12,
                          img(src = "UoG_logo.png", height = "80px", align = "left", style = "margin-top: 10px;"),
                          img(src = "FOFR1002_ADC_Logo_Colour_Short.png", height = "100px", align = "right")
                   )
                 )
          ),
          br(),
          fluidRow(
            column(12,
                   box(
                     title = tagList(icon("upload"), "Upload"),
                     width = 12,
                     collapsible = T,
                     elevation = 2,
                     solidHeader = F,
                     status = "danger",
                     p("Disclaimer placeholder will go here"),
                     
                     selectInput("schema_choice", "Select a target table", choices = schema_choices),
                     actionButton("submit_schema", "Start data verification")
                   )   
            )
          ),
          
          fluidRow(
            column(12,
                   div(id = "validated_data_display", style = "display: none;",
                       box(
                         title = tagList(icon("table"), "Validated Data"),
                         width = 12,
                         collapsible = T,
                         elevation = 2,
                         solidHeader = F,
                         status = "success",
                         p("Data validation completed successfully."),
                         DT::dataTableOutput("validated_data_table"),
                         br(),
                         downloadButton("download_validated", "Download Validated Data", 
                                        class = "btn-success")
                       )
                   )
            )
          ),
          
          fluidRow(
            column(12,
                   div(id = "hidden_iframe",
                       box(
                         title = tagList(icon("check-double"), "Verify"),
                         width = 12,
                         collapsible = F,
                         elevation = 2,
                         maximizable = T,
                         solidHeader = F,
                         status = "danger",
                         tags$iframe(
                           id = "OCA_Composer_iframe",
                           src = paste0(composer_url, "/oca-data-validator"),
                           height = "1200px",
                           width = "100%",
                           style = "border: none; border-radius: 10px; overflow: hidden; background-color: white;"
                         )
                       )   
                   )
            )
          )
        )
      )
    )
  )
)