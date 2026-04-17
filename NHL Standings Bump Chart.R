library(tidyverse)
library(ggbump)
library(ggimage)
library(jsonlite)

# =============================================================================
# Parameters — change year-to-year, no need to touch the other stuff
# =============================================================================

# One date per season you want to compare. 

season_dates <- c(
  "2025" = "2025-04-17",   # end of 2024-25 regular season
  "2026" = "2026-04-16"    # end of 2025-26 regular season
)

# one PNG per team, named exactly "[Team Name].png"
# can also be .jpg but you gotta change the icon filenames
# don't bother with transparent backgrounds, the lines will mess with the logos.

icons_dir <- "./Icons"

# Normalize team names across seasons (relocations / rebrands, and Habs accented e).
# LHS is the name returned by the NHL API in an older season
# RHS is the name you want displayed. Extend as needed.

team_renames <- c(
  "Utah Hockey Club"   = "Utah Mammoth",
  "Montréal Canadiens" = "Montreal Canadiens"
)

# =============================================================================
# 1. Fetch standings from the NHL API
# =============================================================================

fetch_standings <- function(date, label) {
  url  <- sprintf("https://api-web.nhle.com/v1/standings/%s", date)
  json <- jsonlite::fromJSON(url, flatten = TRUE)
  
  tibble::as_tibble(json$standings) |>
    dplyr::transmute(
      Team      = teamName.default,
      Year      = label,
      P.        = pointPctg,
      PtP100    = round(pointPctg * 100, 1),
      rank      = leagueSequence   # NHL's official rank, with tiebreakers applied. Don't mess around with Excel anymore.
    )
}

raw <- purrr::imap_dfr(season_dates, fetch_standings)

# =============================================================================
# 2. Compute derived columns (using api, NTS: don't need to use the Excel steps anymore)
# =============================================================================

latest_year <- names(season_dates)[length(season_dates)]

df <- raw |>
  # normalize relocated / rebranded teams
  dplyr::mutate(Team = dplyr::coalesce(team_renames[Team], Team)) |>
  # "25 (0.488)" style label
  dplyr::mutate(ptsrank = paste0(rank, " (", sprintf("%.3f", P.), ")")) |>
  # rank change vs. the previous season, per team
  dplyr::group_by(Team) |>
  dplyr::arrange(Year, .by_group = TRUE) |>
  dplyr::mutate(changeptsrank = dplyr::lag(rank) - rank) |>
  dplyr::ungroup() |>
  # "18 (+7) (0.561)" style label
  dplyr::mutate(
    ptsrank_latest = dplyr::if_else(
      Year == latest_year & !is.na(changeptsrank),
      sprintf("%d (%+d) (%s)", rank, changeptsrank, sprintf("%.3f", P.)),
      NA_character_
    ),
    Image = file.path(icons_dir, paste0(Team, ".png"))
  )

# =============================================================================
# 3. Plot
# =============================================================================

years <- sort(unique(df$Year))

myplot <- ggplot(df, aes(Year, rank, group = Team, color = Team)) +
  geom_bump(linewidth = 2) +
  geom_image(
    inherit.aes = FALSE, size = 0.0325, data = df,
    mapping = aes(x = Year, y = rank, image = Image)
  ) +
  # left-side labels
  geom_text(
    data = df %>% filter(Year == min(Year)),
    aes(x = Year, label = ptsrank, color = "#000000"),
    size = 3, hjust = 1, nudge_x = -0.035
  ) +
  # right-side labels
  geom_text(
    data = df %>% filter(Year == max(Year)),
    aes(x = Year, label = ptsrank_latest, color = "#000000"),
    size = 3, hjust = 0, nudge_x = 0.035
  ) +
  theme_minimal() +
  scale_x_discrete(breaks = years) +
  scale_y_reverse() +
  theme(
    legend.position = "none",
    panel.grid      = element_blank(),
    axis.line       = element_blank(),
    axis.text.y     = element_blank(),
    axis.title.x    = element_blank(),
    axis.title.y    = element_blank(),
    axis.text.x     = element_blank(), #change for year labels if 3+ years i guess
    plot.subtitle   = element_text(family = "sans", face = "bold", size = 10, hjust = 0.5),
    plot.title      = element_text(family = "sans", face = "bold", size = 12, hjust = 0.5)
  ) +
  labs(
    title    = "End of Regular Season Standings",
    subtitle = " 2024-25 vs. 2025-26"
  ) +
  scale_color_manual(values = c(
    "Washington Capitals"   = "#C8102E", "Minnesota Wild"         = "#154734",
    "Vegas Golden Knights"  = "#B4975A", "Winnipeg Jets"          = "#041E42",
    "Los Angeles Kings"     = "#111111", "Carolina Hurricanes"    = "#CE1126",
    "Florida Panthers"      = "#C8102E", "New Jersey Devils"      = "#CE1126",
    "Dallas Stars"          = "#006847", "Toronto Maple Leafs"    = "#00205b",
    "Vancouver Canucks"     = "#00205B", "Tampa Bay Lightning"    = "#002868",
    "Edmonton Oilers"       = "#041E42", "Boston Bruins"          = "#FFB81C",
    "New York Rangers"      = "#0038A8", "Calgary Flames"         = "#D2001C",
    "Colorado Avalanche"    = "#6F263D", "Utah Mammoth"           = "#71AFE5",
    "Seattle Kraken"        = "#99d9d9", "New York Islanders"     = "#F47d30",
    "St. Louis Blues"       = "#002F87", "Philadelphia Flyers"    = "#F74902",
    "Columbus Blue Jackets" = "#002654", "Pittsburgh Penguins"    = "#FCB514",
    "Ottawa Senators"       = "#DA1A32", "Buffalo Sabres"         = "#003087",
    "Anaheim Ducks"         = "#F47A38", "Detroit Red Wings"      = "#CE1126",
    "Montreal Canadiens"    = "#AF1E2D", "San Jose Sharks"        = "#006D75",
    "Nashville Predators"   = "#FFB81C", "Chicago Blackhawks"     = "#CF0A2C"
  ))

ggsave("2025-26 End of Season.png", plot = myplot,
       height = 1750, width = 2500, units = "px", dpi = 320)
