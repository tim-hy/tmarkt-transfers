# tmarkt-transfers


Data on European football clubs' player transfers, as found on [Transfermarkt](https://www.transfermarkt.com/), since the 1992/93 season (where possible - some data begins at a later date, see table below).

**IMPORTANT**: As of July 2022, transfer fees are now in EUR (taken from the .com Transfermarkt site), not GBP (taken from the .co.uk Transfermarkt site) due to a distortion of older fees being converted with a recent exchange rate.

## Contents

### Data

Transfers can be found in the `data/` directory, in .csv format. Data is from the top 25 first-tier football leagues by revenue (https://en.wikipedia.org/wiki/List_of_professional_sports_leagues_by_revenue):

| League  | Country(ies)  | Reve­nue (€ mil)  | Filename | Transfer year beginning |
|:---:|:---:|:---:|:---:|:---:|
| Premier League (EPL) |  England Wales | 6,100  | premier-league.csv | 1992
| Campeonato Nacional de Liga de Primera División (La Liga) |  Spain | 3,400  | primera-division.csv | 1992
| Fußball-Bundesliga (Bundesliga) |  Germany | 3,000  | 1-bundesliga.csv | 1992
| Lega Nazionale Professionisti Serie A (Serie A) |  Italy | 2,300  | serie-a.csv | 1992
| Championnat de France de football (Ligue 1) |  France  Monaco | 1,700  | ligue-1.csv | 1992
| Major League Soccer (MLS) |  United States  Canada | 1,490 | major-league-soccer.csv | 1995
| Campeonato Brasileiro Série A (Brasileirão) |  Brazil | 1,120 | campeonato-brasileiro-serie-a.csv | 1995
| Chinese Football Association Super League (CSL) |  China | 945 | chinese-super-league.csv | 1993
| Russian Premier League (RPL) |  Russia | 876 | premier-liga.csv | 1992
| J1 League |  Japan | 860 | j1-league.csv | 1995
| Turkish Süper Lig |  Turkey | 670 | super-lig.csv | 1992
| Eredivisie |  Netherlands | 578 | eredivisie.csv | 1992
| Liga MX |  Mexico | 555 | liga-mx-apertura.csv | 1996
| Primeira Liga |  Portugal | 524 | liga-nos.csv | 1992
| Liga Profesional de Fútbol |  Argentina | 490.8 | superliga.csv | 2014
| Belgian First Division A |  Belgium | 445 | juliper-pro-league.csv | 1992
| K League |  South Korea | 287 | k-league-1.csv | 1992
| Saudi Professional League (SPL) |  Saudi Arabia | 254.6 | saudi-professional-league.csv | 2007
| Scottish Premiership (SPL) |  Scotland | 237 | scottish-premiership.csv | 1999
| Swiss Super League |  Switzerland  Liechtenstein | 230 | super-league.csv | 1992
| Austrian Football Bundesliga |  Austria | 224 | bundesliga.csv | 1992
| Danish Superliga |  Denmark | 197 | superligaen.csv | 1992
| Categoria Primera A |  Colombia | 176 | liga-dimayor-i.csv | 2009
| Allsvenskan |  Sweden | 156 | allsvenskan.csv | 2001
| Eliteserien |  Norway | 152 | eliteserien.csv | 1992


### Data Format

| Header | Description | Data Type |
| --- | --- | --- |
| `club_name` | name of club | text |
| `player_name` | name of player | text |
| `position` | position of player | text |
| `club_involved_name` | name of secondary club involved in transfer | text |
| `fee` | raw transfer fee information | text |
| `transfer_movement` | transfer into club or out of club? | text |
| `transfer_period` | transfer window (summer or winter) | text |
| `fee_cleaned` | numeric transformation of `fee`, in EUR millions| numeric |
| `league_name` | name of league `club_name` belongs to | text |
| `year` | year of transfer | text |
| `season` | season of transfer (interpolated from `year`) | text |
| `country` | country of league (contextual only - has no impact on scrape result) | text |

### Adding new leagues

New leagues can be exported by adding rows to the `config/league-meta-expanded.csv` file and running `src/scrape-history.R`. Required columns are `league_name`, `league_id` and `country`. To get `league_name` and `league_id`, extract these from the transfermarkt URL for any leagues' transfer history: 

> www.transfermarkt.com/{LEAGUE_NAME}/transfers/wettbewerb/{LEAGUE_ID}/

For instance, the Belgian Juliper Pro League has a url as follows:

> https://www.transfermarkt.com/jupiler-pro-league/startseite/wettbewerb/BE1

The `country` variable is only present for context (has no impact on the data scrape), and can be entered maually.

**NOTE** - When scraping new leagues, it is recommended to remove all the leagues that have already been downloaded (i.e., only include new leagues in the `config/league-meta-expanded.csv` file). This cuts on processing time and server load.

### Code

Config:
- `config/league-meta.csv` - Legacy list of leagues to scrape (from forked repo).
- `config/league-meta-expanded.csv` - Full list of leagues to scrape (top 25 globally by revenue).

R:

- `src/scrape-summer.R`: retrieves latest summer window's data and appends new observations to CSVs in `data/`
- `src/scrape-winter.R`: retrieves latest winter window's data and appends new observations to CSVs in `data/`
- `src/scrape-history.R`: retrieves transfer history by league and exports to CSVs in `data/`
- `src/functions.R`: local R functions used elsewhere

## Roadmap
- [] Enable Github Actions to automate Summer & Winter scrapes

## Source

All squad data was scraped from [Transfermarkt](https://www.transfermarkt.com/), in accordance with their [terms of use](https://www.transfermarkt.co.uk/intern/anb).
