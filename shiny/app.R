library(shiny)

# UI
ui = fluidPage(
  titlePanel("Snake River Available Spawning Habitat"),
  mainPanel(style = 'width:100% !important; height:90vh;',
    helpText('Please be patient while the map loads.'),
    includeHTML(path = './leaflet/sr_available_habitat_leaflet.html')
    )
)

# Server
server = function(input, output) {
}

# App 
shinyApp(ui = ui, server = server)
