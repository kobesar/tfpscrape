library(rvest)

html_siblings <- function(nodes) {
  # Get the parent nodes of the input nodes
  parents <- nodes %>% html_node(xpath = "..")
  # Get all child nodes of the parent nodes
  siblings <- parents %>% html_nodes(xpath = "./*")
  # Remove the input nodes from the list of siblings
  siblings <- siblings[!siblings %in% nodes]
  return(siblings)
}

# Load the webpage
url <- "https://www.timeforpickleball.com/Locations.html"
page <- read_html(url)

# Find all h2 elements with class 'city-header'
headers <- page %>% html_nodes("h2.city-header")

result <- data.frame()

# Iterate over the headers and extract the div elements between them
for (i in seq_along(headers)) {
  print(i)
  # Find the next sibling of the header element
  sibling <- headers[i] %>% html_node(xpath = "following-sibling::*[1]")

  # Create an empty list to store the div elements
  divs <- list()
  titles <- list()
  
  # Iterate over the siblings until the next header is found
  while (!is.na(sibling) && sibling %>% html_name() != "h2") {
    # Check if the sibling is a div element
    if (sibling %>% html_name() == "div") {
      divs <- c(divs, sibling)
    } else if (sibling %>% html_name() == "h3") {
      titles <- c(titles, sibling)
    }
    # Move to the next sibling
    sibling <- sibling %>% html_node(xpath = "following-sibling::*[1]")
    print(sibling)
  }
  
  result_city <- data.frame()
  
  # Print the div elements for this section
  for (j in seq_along(divs)) {
    info <- list()
    info[["city"]] <- headers[[i]] %>%
      html_text() %>%
      trimws()

    info[["place"]] <- titles[[j]] %>%
      html_text() %>%
      trimws()
    for (tr in divs[[j]] %>% html_nodes("tr")) {
      if (tr %>% html_children() %>% length() > 0) {
        col <- tr %>%
          html_node("td") %>%
          html_node("i") %>%
          html_attr("aria-label") %>%
          trimws()
        
        val <- tr %>%
          html_nodes("td") %>%
          .[[2]] %>%
          html_text() %>%
          trimws()
        
        info[[col]] <- val 
      }
    }
    
    result_city <- bind_rows(result_city, data.frame(info))
  }
  
  result <- bind_rows(result, result_city)
}

# Creating clean columns so it will match the other dataset

cols <- c('place', 'address', 'city', 'state', 'indoor', 'outdoor', 'players', 'total_courts', 'comments', 'updated')

result_final <- result %>% mutate(indoor = (str_detect(str_to_lower(Indoor.or.Outdoor.), "indoor"))*1,
         outdoor = (str_detect(str_to_lower(Indoor.or.Outdoor.), "outdoor"))*1,
         total_courts = NA,
         state = "Washington",
         players = NA,
         address = Map,
         updated = NA,
         comments = NA.) %>% 
  select(c("place", "Map", "city", "state", "indoor", "outdoor", "players", "total_courts", "comments", "updated"))

write.csv(result_final, paste0("data/tfp_", str_replace_all(Sys.Date(), "-", "_"), ".csv"))
write.csv(result, paste0("data/tfp_", str_replace_all(Sys.Date(), "-", "_"), "_raw.csv"))
