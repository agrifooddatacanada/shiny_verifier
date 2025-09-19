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
      base_dir <- "verified_data"
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
      
      showNotification("Schema sent to verifier", type = "message")
      
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
        paste0("Verification complete! Loaded ", nrow(verified_df), " rows and ", 
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
  
  # Clear token data when modal is cancelled
  observeEvent(input$modal_cancel, {
    token_owner_info(NULL)
    token_error_message(NULL)
    removeModal()
  })
  
  # Clear token data when confirmation modal is cancelled
  observeEvent(input$confirm_modal_cancel, {
    token_owner_info(NULL)
    token_error_message(NULL)
    removeModal()
  })
  
  # Show GitHub submission modal
  observeEvent(input$submit_to_github, {
    req(verified_data())
    
    # Pre-fill sensible defaults
    selected_file_id <- input$schema_choice
    json_path <- schema_config[[selected_file_id]]$path
    table_name <- tools::file_path_sans_ext(basename(json_path))
    clean_table_name <- gsub("[^a-zA-Z0-9_]", "_", table_name)
    clean_table_name <- gsub("_+", "_", clean_table_name)
    clean_table_name <- gsub("^_|_$", "", clean_table_name)
    timestamp <- format(Sys.time(), "%Y-%m-%dT%H-%M-%SZ", tz = "UTC")
    default_filename <- paste0(timestamp, "_", clean_table_name, ".csv")
    default_message <- paste("Add verified data:", default_filename)
    
    showModal(modalDialog(
      title = "Submit Verified Data to GitHub",
      size = "l",
      easyClose = FALSE,
      footer = tagList(
        actionButton("modal_cancel", "Cancel", class = "btn-secondary"),
        actionButton("confirm_github_upload", "Submit", class = "btn-primary")
      ),
      fluidRow(
        column(6,
               textInput("github_owner", "Repository Owner (user or org)", value = "", width = '100%')
        ),
        column(6,
               textInput("github_repo", "Repository Name", value = "", width = '100%')
        )
      ),
      fluidRow(
        column(6,
               textInput("github_branch", "Branch", value = "main", width = '100%')
        ),
        column(6,
               textInput("github_dir", "Destination Directory in Repo", value = "verified_data", width = '100%')
        )
      ),
      fluidRow(
        column(12,
               passwordInput("github_token", "GitHub Personal Access Token", value = "", width = '100%')
        )
      ),
      fluidRow(
        column(12,
               helpText("Note: Committer name and email will be automatically retrieved from your GitHub token.")
        )
      ),
      fluidRow(
        column(12,
               conditionalPanel(
                 condition = "output.token_validated",
                 div(style = "margin-top: 10px; padding: 10px; background-color: #d4edda; border: 1px solid #c3e6cb; border-radius: 4px;",
                     h5("Token Validated", style = "color: #155724; margin: 0;"),
                     textOutput("token_owner_display")
                 )
               ),
               conditionalPanel(
                 condition = "output.token_error",
                 div(style = "margin-top: 10px; padding: 10px; background-color: #f8d7da; border: 1px solid #f5c6cb; border-radius: 4px;",
                     h5("Token Error", style = "color: #721c24; margin: 0;"),
                     textOutput("token_error_message")
                 )
               )
        )
      ),
      tags$br(),
      fluidRow(
        column(12,
               textAreaInput("github_commit_message", "Commit Message", value = default_message, 
                           rows = 3, resize = "vertical", width = '100%')
        )
      ),
      tags$hr(),
      helpText("Note: These values are used only for this submission and are not saved or persisted.")
    ))
  })
  
  # Reactive values to store token owner info and error
  token_owner_info <- reactiveVal(NULL)
  token_error_message <- reactiveVal(NULL)
  
  # Validate token and get owner info when token is entered
  observeEvent(input$github_token, {
    req(input$github_token)
    
    if (nchar(input$github_token) > 10) {  # Basic validation - GitHub tokens are longer
      tryCatch({
        user_resp <- httr::GET(
          "https://api.github.com/user",
          httr::add_headers(
            Authorization = paste("Bearer", input$github_token),
            Accept = "application/vnd.github+json"
          )
        )
        
        status_code <- httr::status_code(user_resp)
        # cat("GitHub API status code:", status_code, "\n")
        
        if (status_code == 200) {
          user_info <- httr::content(user_resp, as = "parsed")
          # cat("User info retrieved for:", user_info$login, "\n")
          token_owner_info(list(
            login = user_info$login,
            name = ifelse(is.null(user_info$name) || user_info$name == "", user_info$login, user_info$name),
            email = ifelse(is.null(user_info$email) || user_info$email == "", paste0(user_info$login, "@users.noreply.github.com"), user_info$email)
          ))
          token_error_message(NULL)  # Clear any previous error
        } else {
          error_content <- httr::content(user_resp, as = "text")
          cat("GitHub API error:", status_code, "-", error_content, "\n")
          token_owner_info(NULL)
          token_error_message(paste("GitHub API error", status_code, ":", error_content))
        }
      }, error = function(e) {
        # cat("Error validating token:", e$message, "\n")
        token_owner_info(NULL)
        token_error_message(paste("Network error:", e$message))
      })
    } else {
      token_owner_info(NULL)
      token_error_message(NULL)
    }
  })
  
  # Show confirmation modal before upload
  observeEvent(input$confirm_github_upload, {
    req(verified_data())
    
    # Check if we have token owner info
    if (is.null(token_owner_info())) {
      showNotification("Please enter a valid GitHub token first.", type = "error")
      return()
    }
    
    # Show confirmation modal
    showModal(modalDialog(
      title = "Confirm GitHub Upload",
      size = "m",
      easyClose = FALSE,
      footer = tagList(
        actionButton("confirm_modal_cancel", "Cancel", class = "btn-secondary"),
        actionButton("final_confirm_upload", "Confirm Upload", class = "btn-primary")
      ),
      div(
        h4("Upload Details:"),
        p(strong("Repository:"), paste0(input$github_owner, "/", input$github_repo)),
        p(strong("Branch:"), input$github_branch),
        p(strong("Path:"), file.path(input$github_dir, format(Sys.time(), "%Y"), format(Sys.time(), "%m"), 
                                   paste0(format(Sys.time(), "%Y-%m-%dT%H-%M-%SZ"), "_", 
                                          tools::file_path_sans_ext(basename(schema_config[[input$schema_choice]]$path)), ".csv"))),
        p(strong("Commit Message:"), input$github_commit_message),
        tags$hr(),
        h4("Committer Information:"),
        p(strong("Name:"), token_owner_info()$name),
        p(strong("Email:"), token_owner_info()$email),
        p(strong("Username:"), token_owner_info()$login)
      )
    ))
  })
  
  # Final upload handler
  observeEvent(input$final_confirm_upload, {
    req(verified_data())
    
    tryCatch({
      # Validate required fields
      if (is.null(input$github_owner) || input$github_owner == "") {
        showNotification("Please enter the repository owner.", type = "error"); return()
      }
      if (is.null(input$github_repo) || input$github_repo == "") {
        showNotification("Please enter the repository name.", type = "error"); return()
      }
      if (is.null(token_owner_info())) {
        showNotification("Please enter a valid GitHub token.", type = "error"); return()
      }
      
      # Use stored token owner info
      token_owner <- token_owner_info()$login
      token_name <- token_owner_info()$name
      token_email <- token_owner_info()$email
      
      # Build filename and path
      selected_file_id <- input$schema_choice
      json_path <- schema_config[[selected_file_id]]$path
      table_name <- tools::file_path_sans_ext(basename(json_path))
      clean_table_name <- gsub("[^a-zA-Z0-9_]", "_", table_name)
      clean_table_name <- gsub("_+", "_", clean_table_name)
      clean_table_name <- gsub("^_|_$", "", clean_table_name)
      timestamp <- format(Sys.time(), "%Y-%m-%dT%H-%M-%SZ", tz = "UTC")
      filename <- paste0(timestamp, "_", clean_table_name, ".csv")
      current_year <- format(Sys.time(), "%Y", tz = "UTC")
      current_month <- format(Sys.time(), "%m", tz = "UTC")
      dest_dir <- ifelse(is.null(input$github_dir) || input$github_dir == "", "verified_data", input$github_dir)
      repo_path <- file.path(dest_dir, current_year, current_month, filename)
      
      # Create CSV content in memory
      tmp <- tempfile(fileext = ".csv")
      utils::write.csv(verified_data(), tmp, row.names = FALSE)
      raw_bytes <- readBin(tmp, what = "raw", n = file.info(tmp)$size)
      unlink(tmp)
      b64 <- base64enc::base64encode(raw_bytes)
      
      # Prepare request
      owner <- input$github_owner
      repo <- input$github_repo
      branch <- ifelse(is.null(input$github_branch) || input$github_branch == "", "main", input$github_branch)
      url <- sprintf("https://api.github.com/repos/%s/%s/contents/%s", owner, repo, utils::URLencode(repo_path))
      commit_message <- ifelse(is.null(input$github_commit_message) || input$github_commit_message == "",
                               paste("Add verified data:", filename), input$github_commit_message)
      committer <- list(
        name = token_name,
        email = token_email
      )
      
      body <- list(
        message = commit_message,
        content = b64,
        branch = branch,
        committer = committer
      )
      
      resp <- httr::PUT(
        url,
        httr::add_headers(
          Authorization = paste("Bearer", input$github_token),
          Accept = "application/vnd.github+json"
        ),
        body = body,
        encode = "json"
      )
      
      status <- httr::status_code(resp)
      content_txt <- tryCatch(httr::content(resp, as = "text", encoding = "UTF-8"), error = function(e) "")
      content_json <- tryCatch(jsonlite::fromJSON(content_txt), error = function(e) NULL)
      
      if (status == 201) {
        # Clear all token-related data
        token_owner_info(NULL)
        token_error_message(NULL)
        
        # Force garbage collection to free memory
        gc()
        
        removeModal()  # Close confirmation modal
        removeModal()  # Close original modal
        showNotification(paste("File uploaded to GitHub successfully as", token_owner), type = "message")
      } else {
        msg <- if (!is.null(content_json$message)) content_json$message else paste("GitHub API error (status", status, ")")
        showNotification(paste("Upload failed:", msg), type = "error")
      }
      
      # Explicitly drop sensitive values (not persisted anywhere)
      invisible(NULL)
      
    }, error = function(e) {
      showNotification(paste("Unexpected error:", e$message), type = "error")
    })
  })
  
  # Token validation outputs
  output$token_validated <- reactive({
    !is.null(token_owner_info())
  })
  outputOptions(output, "token_validated", suspendWhenHidden = FALSE)
  
  output$token_error <- reactive({
    !is.null(token_error_message())
  })
  outputOptions(output, "token_error", suspendWhenHidden = FALSE)
  
  output$token_owner_display <- renderText({
    if (!is.null(token_owner_info())) {
      paste0("Logged in as: ", token_owner_info()$name, " (", token_owner_info()$login, ")")
    }
  })
  
  output$token_error_message <- renderText({
    token_error_message()
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