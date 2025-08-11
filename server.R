
# Load schema mapping from config file (needed for server logic)
schema_config <- jsonlite::fromJSON("config/schemas.json")

# Define Server
server <- function(input, output, session) {
  # Reactive value to store validated data
  validated_data <- reactiveVal(NULL)
  
  # Handle schema submission
  observeEvent(input$submit_schema, {
    req(input$schema_choice)
    
    # Hide validated data display if it was shown before
    shinyjs::hide("validated_data_display")
    
    # Show the iframe for verification
    shinyjs::show("hidden_iframe", anim = TRUE, animType = 'slide')
    
    tryCatch({
      # Prepare schema data to be sent to Composer
      selected_file_id <- input$schema_choice
      schema_path <- schema_config[[selected_file_id]]$path
      
      # Read and parse JSON file
      json_file <- jsonlite::fromJSON(schema_path, simplifyVector = FALSE)
      
      # Validate JSON structure before sending
      if (is.null(json_file)) {
        showNotification("Error: Invalid JSON file", type = "error")
        return()
      }
      
      # Send selected schema data to the embedded Composer iframe
      session$sendCustomMessage(
        type = "json2iframe",
        message = list(
          data = json_file
        )
      )
      
      showNotification("Schema sent to validator", type = "message")
      
    }, error = function(e) {
      showNotification(paste("Error preparing schema:", e$message), type = "error")
      cat("Error in submit_schema:", e$message, "\n")
    })
  })
  
  # Handle validated data received from iframe
  observeEvent(input$validated_data, {
    
    # Process the validated CSV data here
    showNotification("Validated data received successfully!", type = "message")
    
    # Parse CSV data 
    tryCatch({
      validated_df <- read.csv(text = input$validated_data, stringsAsFactors = FALSE)
      
      # Store the data in reactive value
      validated_data(validated_df)
      
      # Hide the iframe/verify box 
      shinyjs::hide("hidden_iframe", anim = TRUE, animType = 'slide')
      
      # Show the validated data display section
      shinyjs::show("validated_data_display", anim = TRUE, animType = 'slide')
      
      showNotification(
        paste0("Validation complete! Loaded ", nrow(validated_df), " rows and ", 
               ncol(validated_df), " columns."), 
        type = "message"
      )
      
    }, error = function(e) {
      cat("Error parsing validated CSV:", e$message, "\n")
      showNotification(paste("Error processing validated data:", e$message), type = "error")
    })
  })
  
  # Render the data table
  output$validated_data_table <- DT::renderDataTable({
    req(validated_data())
    
    DT::datatable(
      validated_data(),
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel'),
        columnDefs = list(list(className = 'dt-center', targets = "_all"))
      ),
      filter = 'top',
      rownames = FALSE,
      class = 'cell-border stripe'
    )
  })
  
  # Download handler for validated data
  output$download_validated <- downloadHandler(
    filename = function() {
      paste0("validated_data_", Sys.Date(), ".csv")
    },
    content = function(file) {
      req(validated_data())
      write.csv(validated_data(), file, row.names = FALSE)
    }
  )
}