# NHL Standings Bump Chart

R Script to visualize how NHL teams move in the standings between seasons using a bump chart with team logos.

Pulls official standings directly from the NHL API, computes rank changes year-over-year, and generates a bump chart using ggbump.


## Dependencies

Install required R packages:

```r
install.packages(c("tidyverse", "ggbump", "ggimage", "jsonlite"))
```

---

## Setup

### 1. Configure Seasons

Define the seasons you want to compare:

```r
season_dates <- c(
  "2025" = "2025-04-17",
  "2026" = "2026-04-16"
)
```

Each value is a date representing the standings snapshot (typically end of regular season). Must use in-season date or it'll return empty. 

If you want the games played on a specific date included, use the next calendar day. 

---

### 2. Add Team Logos

Set your icons directory if needed, or download Icons folder and keep in same parent folder as script:

```r
icons_dir <- "./Icons"
```

Requirements:

- One image per team  
- Filename must match exact team name from API  
- Format: `.png` (or adjust script if using `.jpg`) 
- Don't bother with transparent backgrounds, ggbump/lines will just conflict with the logo.


---

### 3. Handle Team Renames (Optional)

Normalize team names across seasons:

```r
team_renames <- c(
  "Utah Hockey Club"   = "Utah Mammoth",
  "Montréal Canadiens" = "Montreal Canadiens"
)
```

This prevents breaks when franchises relocate or rebrand. Also fixes Habs accent encoding stuff. Leave this the same unless a team relocates or changes names and I haven't included the change.

---



<img width="2500" height="1750" alt="2025-26 End of Season" src="https://github.com/user-attachments/assets/5d7b7eb6-7cc8-4449-9000-785cab754fb3" />
