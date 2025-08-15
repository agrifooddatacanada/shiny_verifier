# Define Server
server <- function(input, output, session) {
  # Reactive value to store verified data
  verified_data <- reactiveVal(NULL)
  
  # Function to create folder structure and save file
  save_verified_data <- function(data, table_name) {
    tryCatch({
      # Create timestamp in UTC using ISO 8601 format
      timestamp <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
      
      # Create base upload directory
      base_dir <- "upload_files"
      if (!dir.exists(base_dir)) {
        dir.create(base_dir, recursive = TRUE)
      }
      
      # Create year and month subdirectories
      current_year <- format(Sys.time(), "%Y", tz = "UTC")
      current_month <- format(Sys.time(), "%m", tz = "UTC")
      
      year_dir <- file.path(base_dir, current_year)
      month_dir <- file.path(year_dir, current_month)
      
      if (!dir.exists(year_dir)) {
        dir.create(year_dir, recursive = TRUE)
      }
      if (!dir.exists(month_dir)) {
        dir.create(month_dir, recursive = TRUE)
      }
      
      # Create filename with ISO 8601 timestamp and table name
      # Clean table name for filename (remove special characters, replace spaces with underscores)
      clean_table_name <- gsub("[^a-zA-Z0-9_]", "_", table_name)
      clean_table_name <- gsub("_+", "_", clean_table_name) # Replace multiple underscores with single
      clean_table_name <- gsub("^_|_$", "", clean_table_name) # Remove leading/trailing underscores
      
      # Use ISO 8601 format for filename (replace colons with hyphens for filesystem compatibility)
      filename_timestamp <- format(Sys.time(), "%Y-%m-%dT%H-%M-%SZ", tz = "UTC")
      filename <- paste0(filename_timestamp, "_", clean_table_name, ".csv")
      filepath <- file.path(month_dir, filename)
      
      # Save the CSV file
      write.csv(data, filepath, row.names = FALSE)
      
      # Return success message with file path
      return(list(
        success = TRUE,
        filepath = filepath,
        message = paste("File saved successfully to:", filepath)
      ))
      
    }, error = function(e) {
      return(list(
        success = FALSE,
        error = e$message,
        message = paste("Error saving file:", e$message)
      ))
    })
  }
  
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
      
      # Get the selected table name from the JSON file name instead of display name
      selected_file_id <- input$schema_choice
      json_path <- schema_config[[selected_file_id]]$path
      
      # Extract table name from the JSON file name (remove path and .json extension)
      table_name <- basename(json_path)
      table_name <- tools::file_path_sans_ext(table_name)
      
      # Save the verified data to file
      save_result <- save_verified_data(verified_df, table_name)
      
      if (save_result$success) {
        showNotification(save_result$message, type = "message")
        cat("File saved successfully:", save_result$filepath, "\n")
      } else {
        showNotification(save_result$message, type = "error")
        cat("Error saving file:", save_result$error, "\n")
      }
      
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
      req(verified_data())
      # Get the selected table name from the JSON file name instead of display name
      selected_file_id <- input$schema_choice
      json_path <- schema_config[[selected_file_id]]$path
      
      # Extract table name from the JSON file name (remove path and .json extension)
      table_name <- basename(json_path)
      table_name <- tools::file_path_sans_ext(table_name)
      
      clean_table_name <- gsub("[^a-zA-Z0-9_]", "_", table_name)
      clean_table_name <- gsub("_+", "_", clean_table_name)
      clean_table_name <- gsub("^_|_$", "", clean_table_name)
      
      # Use ISO 8601 format for filename (replace colons with hyphens for filesystem compatibility)
      timestamp <- format(Sys.time(), "%Y-%m-%dT%H-%M-%SZ", tz = "UTC")
      paste0(timestamp, "_", clean_table_name, ".csv")
    },
    content = function(file) {
      req(verified_data())
      write.csv(verified_data(), file, row.names = FALSE)
    }
  )
}