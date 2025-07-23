library(bs4Dash)
library(shiny)
library(shinyjs)
library(shinyWidgets)

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
                   # shinyjs::hidden(
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
                     # )
                   )
            )
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  # Render iframe
  observeEvent(input$submit_schema, {
    req(input$schema_choice)
    
    shinyjs::show("hidden_iframe", anim = T, animType = 'slide')
    
    # Prepare schema data to be sent to Composer
    selected_file_id <- input$schema_choice
    schema_path <- schema_config[[selected_file_id]]$path
    json_file <- jsonlite::fromJSON(schema_path)
    
    # Send selected schema data to the embedded Composer iframe
    session$sendCustomMessage(
      type = "json2iframe", 
      message = list(
        type = "JSON_SCHEMA", 
        data = json_file
      ))
    
  })
  
  observeEvent(input$validated_data, {
    # Logics to handle verified data here
  })
}

shinyApp(ui, server)