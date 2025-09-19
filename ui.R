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
      HTML(sprintf("
      // message listener for receiving data from iframe
      
      window.addEventListener('message', function(event) {
        // Check the origin of the message for security
      	const allowedOrigins = [%s];
        if (!allowedOrigins.includes(event.origin)) {
            // Origin is not allowed
              console.log('Message from unknown origin:', event.origin);
              return;
        }
        // Check the type of the message if this is verified data from the verifier
        if (event.data && event.data.type === 'VERIFIED_DATA') {
          // Debug: log the data type
          console.log('Data type:', typeof event.data.data);
          
          // Handle different data types
          if (typeof event.data.data === 'string') {
            // If it's a string (like CSV), split by lines and show first 10
            const lines = event.data.data.split('\\n');
            console.log('Received verified data (first 10 lines):', lines.slice(0, 10));
            console.log('Total number of lines:', lines.length);
          } else {
            console.log('Received verified data:', event.data.data);
          }
          
          // Send the verified data back to Shiny
          Shiny.setInputValue('verified_data', event.data.data, {priority: 'event'});
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
    ", paste0("'", composer_url, "'")))
    ),
    
    tabItems(
      tabItem(
        tabName = "app",
        
        tagList(
          column(12,
                 fluidRow(
                   column(12,
                          img(src = "UoG_logo.png", height = "80px", align = "left", style = "margin-top: 10px;"),
                          img(src = "ADC_logo.png", height = "100px", align = "right")
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
          shinyjs::hidden(
            div(id = "hidden_iframe",
                fluidRow(
                  column(12,
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
                             src = paste0(composer_url, "/oca-data-verifier"),
                             height = "1200px",
                             width = "100%",
                             style = "border: none; border-radius: 10px; overflow: hidden; background-color: white;"
                           )
                         )   
                  )
                )
            )
          ),
          shinyjs::hidden(
            div(id = "verified_data_display",
                fluidRow(
                  column(12,
                         box(
                           title = tagList(icon("table"), "Verified Data"),
                           width = 12,
                           collapsible = T,
                           elevation = 2,
                           solidHeader = F,
                           status = "success",
                           p("Data verification completed successfully."),
                           downloadButton("download_verified", "Download Verified Data"),
                           actionButton("submit_to_github", tagList(icon("github"), "Submit to GitHub")),
                           br(),
                           br(),
                           DT::dataTableOutput("verified_data_table")
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