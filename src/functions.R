# make the transfer page URL
construct_url <- function(
    league_id, league_name, season_id, window
    ) {
  
  window_format <- case_when(
    window == "Summer" ~ "s",
    window == "Winter" ~ "w"
  )
  
  transfers_url <- glue(
    "https://www.transfermarkt.com/{league_name}/transfers/wettbewerb/{league_id}/plus/?saison_id={season_id}&s_w={window_format}"
  )
  
  return(transfers_url)
}

# extract transfers data from page
extract_transfers <- function(league_id, league_name, season_id, window) {
  
  transfers_url <- construct_url(
    league_id, league_name, season_id, window = window
  )
  cat("Scraping", transfers_url, "\n")
  # Error-catch page pull - iterate until completion
  while(TRUE){
    tryCatch({
      page <-  GET(transfers_url, config = httr::config(connecttimeout = 120)) %>% read_html()
      message("Extracted!\n")
      break
    }, error=function(e){
      print(e)
      message("Retrying...")
    })
  }

  # isolate leagues club names
  clubs <- page %>% 
    html_elements(".content-box-headline--logo") %>%
    html_text2()

  # get leagues transfers
  transfers <- page %>% 
    html_elements(".large-8 .responsive-table") %>% 
    html_table(
      header = TRUE, fill = TRUE, trim = TRUE
    )
  
  if (length(transfers) == 0) return(data.frame())
  
  # get player names (which get botched in the table above)
  player_names <- page %>% 
    html_elements(".large-8 .responsive-table .di.nowrap .hide-for-small a") %>%
    html_attr("title")

  clubs_tidy <- rep(clubs, each = 2)
  
  # create tidy transfers data frame
  transfers_tidy <- map_dfr(seq_along(transfers), function(x) {
    
    data <- transfers[[x]]
    
    # clean column names
    data <- clean_names(data)
    
    # assign transfer type
    data$transfer_movement <- case_when(
      "in" %in% colnames(data) ~ "in",
      "out" %in% colnames(data) ~ "out"
    )
    
    # deal with buy/sell data structure differences
    if ("in" %in% colnames(data)) {
      
      data <- data %>% 
        rename(player_name='in', club_involved_name=left_2) %>% 
        mutate(
          club_name = clubs_tidy[[x]]
        ) %>% 
        select(-left)
      
    } else if ("out" %in% colnames(data)) {
      
      data <- data %>% 
        rename(player_name='out', club_involved_name=joined_2) %>% 
        mutate(
          club_name = clubs_tidy[[x]]
        ) %>% 
        select(-joined)
    }
    
    # select columns to keep
    data <- data %>% 
      select(
        club_name, player_name, age, position, 
        club_involved_name, fee, transfer_movement
      ) %>% 
      mutate(
        age = suppressWarnings(as.numeric(data$age))
      )

    return(data)
  })
  
  transfers_tidy <- transfers_tidy %>% 
    # remove whitespace from chr vars
    mutate_if(is.character, str_trim) %>% 
    # remove clubs w/ no moves
    dplyr::filter(
      !club_name %in% c("No departures", "No arrivals", "No new arrivals"),
      !player_name %in% c("No departures", "No arrivals", "No new arrivals")
      )

  ## Get full (non-abbr.) team 'to' name and replace current abbr. version
  # List team 'to' names
  teamnames <- page %>% 
    html_elements(".no-border-links, .verein-flagge-transfer-cell")
  # create empty df
  team_list <- data.frame(matrix(ncol=1,nrow=0))
  colnames(team_list) <- "teamname"
  # Iterate team names - get non-abbr. version, but if 
  # non-existent (i.e. non-club transfer), get text from parent element
  for (i in 1:length(teamnames)) {
    name <- teamnames[i] %>% html_elements(., "a") %>% html_attr("title")
    
    if (length(name) < 1) {
      x <- teamnames[i] %>% html_text() %>% str_trim()
      team_list[i,] <- x
    }
    else {
      x <- name
      team_list[i, ] <- x
    }
  }
  transfers_tidy["club_involved_name"] <- team_list
  
  # remove duplicate player name thing
  if (nrow(transfers_tidy) == 0) return(data.frame())
    
  transfers_tidy$player_name <- player_names
  transfers_tidy$transfer_period <- window
  
  return(transfers_tidy)
  
}

# tidy up transfer data
tidy_transfers <- function(x, league_name, season_id, country) {
  
  transfers_tidy <- x %>% 
    mutate(
      # deal with fees
      fee_cleaned = case_when(
        str_sub(fee, -1, -1) == "m" ~ suppressWarnings(as.numeric(str_extract(fee, "\\d+\\.*\\d*"))),
        str_sub(fee, -1, -1) == "k" ~ suppressWarnings(as.numeric(str_extract(fee, "\\d+\\.*\\d*")))/1000,
        str_sub(fee, -3, -1) == "Th." ~ suppressWarnings(as.numeric(str_extract(fee, "\\d+\\.*\\d*")))/1000,
        str_detect(fee, regex("free transfer", ignore_case = TRUE)) ~ 0,
        str_detect(fee, regex("loan", ignore_case = TRUE)) ~ NA_real_,
        fee %in% c("-", "?") ~ NA_real_
      ),
      # add relevant metadata
      club_name = str_trim(club_name),
      league_name = str_replace_all(
        str_to_title(league_name), pattern = "-", replacement = " "
      ),
      year = season_id,
      season = paste0(year, "/", year + 1),
      country = country
    )
  
  return(transfers_tidy)
}

# scrape a league seasons transfers
get_transfers_history <- function(league_id, league_name, season_id, country) {
  
  # get transfers data
  summer_transfers <- extract_transfers(
    league_id, league_name, season_id, window = "Summer"
    )
  
  winter_transfers <- extract_transfers(
    league_id, league_name, season_id, window = "Winter"
    )
  
  transfers <- bind_rows(summer_transfers, winter_transfers)
  
  if (nrow(transfers) == 0) return(data.frame())
  
  transfers_tidy <- tidy_transfers(transfers, league_name, season_id, country)
  
  message("Sleeping...")
  Sys.sleep(5)
  return(transfers_tidy)
  
}

get_transfers_summer <- function(league_id, league_name, season_id, country) {
  
  # get transfers data
  summer_transfers <- extract_transfers(
    league_id, league_name, season_id, window = "Summer"
  )

  if (nrow(summer_transfers) == 0) return(data.frame())
  
  transfers_tidy <- tidy_transfers(summer_transfers, league_name, season_id, country)
  
  return(transfers_tidy)
}

get_transfers_winter <- function(league_id, league_name, season_id, country) {
  
  # get transfers data
  winter_transfers <- extract_transfers(
    league_id, league_name, season_id, window = "Winter"
  )
  
  if (nrow(winter_transfers) == 0 || is.null(winter_transfers)) return(data.frame())
  
  transfers_tidy <- tidy_transfers(winter_transfers, league_name, season_id, country)
  
  return(transfers_tidy)
}
