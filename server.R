# Define Server
server <- function(input, output, session) {
  # Reactive value to store verified data
  verified_data <- reactiveVal(NULL)
  
  # Handle schema submission
  observeEvent(input$submit_schema, {
    req(input$schema_choice)
    
    # Hide verified data display if it was shown before
    shinyjs::hide("verified_data_display")
    
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
  
  # Handle verified data received from iframe
  observeEvent(input$verified_data, {
    
    # Process the verified CSV data here
    showNotification("Verified data received successfully!", type = "message")
    
    # Parse CSV data 
    tryCatch({
      verified_df <- read.csv(text = input$verified_data, stringsAsFactors = FALSE)
      
      # Store the data in reactive value
      verified_data(verified_df)
      
      # Hide the iframe/verify box 
      shinyjs::hide("hidden_iframe", anim = TRUE, animType = 'slide')
      
      # Show the verified data display section
      shinyjs::show("verified_data_display", anim = TRUE, animType = 'slide')
      
      showNotification(
        paste0("Validation complete! Loaded ", nrow(verified_df), " rows and ", 
               ncol(verified_df), " columns."), 
        type = "message"
      )
      
    }, error = function(e) {
      cat("Error parsing verified CSV:", e$message, "\n")
      showNotification(paste("Error processing verified data:", e$message), type = "error")
    })
  })
  
  # Render the data table
  output$verified_data_table <- DT::renderDataTable({
    req(verified_data())
    
    DT::datatable(
      verified_data(),
      options = list(
        dom = "tp",
        scrollX = TRUE,
        columnDefs = list(list(className = 'dt-center', targets = "_all"))
      ),
      rownames = FALSE,
      class = 'row-border stripe compact nowrap'
    )
  })
  
  # Download handler for verified data
  output$download_verified <- downloadHandler(
    filename = function() {
      paste0("varified_data_", Sys.Date(), ".csv")
    },
    content = function(file) {
      req(verified_data())
      write.csv(verified_data(), file, row.names = FALSE)
    }
  )
}