library(bs4Dash)
library(shiny)
library(shinyjs)
library(shinyWidgets)

# Get Azure URL from environment variable
azure_url <- Sys.getenv("REACT_APP_URL")

# Format folder names for dropdown display
format_schema_name <- function(name) {
  name <- gsub("_", " ", name)
  name <- tools::toTitleCase(name)
  return(name)
}

# List schema folders and create dropdown choices
schema_folder_names <- list.dirs(path = "Test Schemas", full.names = FALSE, recursive = FALSE)
schema_choices <- setNames(c("", schema_folder_names), c("Select a Schema", sapply(schema_folder_names, format_schema_name)))

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
    collapsed = F,
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
    tabItems(
      tabItem(
        tabName = "app",
                
        tagList(
          column(12,
                 fluidRow(
                   column(12,
                          img(src = "UoG_logo.png", height = "80px", align = "left"),
                          img(src = "FOFR1002_ADC_Logo_Colour_Short.png", height = "80px", align = "right")
                   )
                 )
          ),
          br(),
          fluidRow(
            column(12,
                   box(
                     title = tagList(icon("upload"), "Upload"),
                     width = 12,
                     collapsible = F,
                     elevation = 2,
                     solidHeader = F,
                     status = "danger",
                     p("Disclaimer placeholder will go here"),
                     
                     selectInput("schema_choice", "Select a Local Schema", choices = schema_choices, selected = ""),
                     actionButton("submit_schema", "Submit")
                   )   
            )
          ),
          fluidRow(
            column(12,
                   shinyjs::hidden(
                     div(id = "hidden_iframe",
                         box(
                           title = tagList(icon("check-double"), "Verify"),
                           width = 12,
                           collapsible = F,
                           elevation = 2,
                           solidHeader = F,
                           status = "danger",
                           uiOutput("iframe")  # Output for iframe or dropdown
                         )   
                     )
                   )
            )
          )
        )
      )
    ),
    
    tags$script(HTML("
      // Send data to React
      Shiny.addCustomMessageHandler('sendData', function(data) {
        const iframe = document.getElementById('reactAppIframe');
        if (iframe && iframe.contentWindow) {
          iframe.contentWindow.postMessage(data, '", azure_url, "'); // production
        }
      });

      // Receive validated data from React
      window.addEventListener('message', function(event) {
      // Check if the message is from our React app
      if (event.origin === '", azure_url, "') { //production
        if (event.data.type === 'validatedData') {
          // Send the validated data back to Shiny server
          Shiny.setInputValue('validated_data', {
            data: event.data.data,
            format: event.data.format,
            keepOriginalHeaders: event.data.keepOriginalHeaders,
            metadata: event.data.metadata
          });
        }
      }
    })
  "))
  )
)

server <- function(input, output, session) {
  # Render iframe
  observeEvent(input$submit_schema, {
    req(input$schema_choice)
    
    shinyjs::show("hidden_iframe", anim = T, animType = 'slide')
    
    # Prepare schema data to be sent to Composer
    selected_schema <- input$schema_choice
    schema_path <- file.path("Test Schemas", selected_schema)
    json_files <- list.files(schema_path, pattern = "*.json", full.names = TRUE)
    json_bundle <- lapply(json_files, jsonlite::fromJSON)
    
    # Send selected schema data to the embedded Composer iframe
    session$sendCustomMessage(type = "message", 
                              message = list(
                                data = json_bundle, 
                                schema = selected_schema
                              ))
    
    # Display iframe after schema is selected
    output$iframe <- renderUI({
      tagList(
        tags$iframe(
          id = "reactAppIframe",
          src = paste0(azure_url, "/oca-data-validator"), #production
          height = "2000px",
          width = "100%",
          style = "border: none; border-radius: 10px; overflow: hidden; background-color: white;"
        )
      )
    })
  })
  
  observeEvent(input$validated_data, {
    # Handle the validated data
    data <- input$validated_data$data
    format <- input$validated_data$format
    
    # Save to internal storage
    #if (format == "excel") {
    #  writexl::write_xlsx(data, "path/to/save/validated_data.xlsx")
    #} else {
    #  write.csv(data, "path/to/save/validated_data.csv")
    #}
    
  })
  
}


shinyApp(ui, server)