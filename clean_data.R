pkgs <- c("reshape2", "stringr", "lubridate", "zipcode", "plyr", "ggmap", "data.table")
invisible(lapply(pkgs, require, character.only = TRUE))

## clean up the raw data
mj.us <- read.csv("./data/raw.csv")
mj.us <- data.frame(mj.us[, -1], colsplit(mj.us$location, ",", c("city", "state")))
mj.us$state <- str_trim(mj.us$state)
mj.us <- mj.us[mj.us$state %in% state.name[-c(2,11)], ]
mj.us$date <- mdy(mj.us$date)
mj.us$price <- gsub("[$]", "", mj.us$price)
mj.us$quality <- gsub(" quality", "", mj.us$quality)
mj.us$price <- as.numeric(mj.us$price)
mj.us$amount[mj.us$amount == "an ounce"] <- 28.3
mj.us$amount[mj.us$amount == "25 grams"] <- 25
mj.us$amount[mj.us$amount == "20 grams"] <- 20
mj.us$amount[mj.us$amount == "15 grams"] <- 15
mj.us$amount[mj.us$amount == "a half ounce"] <- 14.15
mj.us$amount[mj.us$amount == "10 grams"] <- 10
mj.us$amount[mj.us$amount == "a quarter"] <- 7.075
mj.us$amount[mj.us$amount == "5 grams"] <- 5
mj.us$amount[mj.us$amount == "an eighth"] <- 3.54
mj.us$amount[mj.us$amount == "a gram"] <- 1
mj.us$amount <- as.numeric(mj.us$amount)
mj.us <- mj.us[mj.us$price != 0 & !(is.na(mj.us$amount)), ]
mj.us$ppg <- mj.us$price / mj.us$amount
mj.us <- mj.us[mj.us$ppg > 1 & mj.us$ppg < 35, ] #dropping rule
mj.us$quality <- factor(mj.us$quality, levels = c("low", "medium", "high"))

## merge in legal status
legality <- read.csv("./data/legality.csv")[, -5]
legality$legal <- mdy(legality$legal)
legality$decrim <- mdy(legality$decrim)
legality$med <- mdy(legality$med)
mj.us$state <- tolower(mj.us$state)
mj.us <- merge(mj.us, legality, by = "state")
mj.us$legal <- ifelse(mj.us$legal <= mj.us$date & !is.na(mj.us$legal), 1, 0)
mj.us$decrim <- ifelse(mj.us$decrim <= mj.us$date & !is.na(mj.us$decrim), 1, 0)
mj.us$med <- ifelse(mj.us$med <= mj.us$date & !is.na(mj.us$med), 1, 0)

## geocode municipalities
mj.us$state.name <- mj.us$state
mj.us$state <- state.abb[match(mj.us$state, tolower(state.name))]
data(zipcode)
zipcode <- ddply(zipcode, .(city, state), summarize, lat = median(latitude), lon = median(longitude))
mj.us <- merge(mj.us, zipcode, by = c("city", "state"), all.x = TRUE)
tgc <- mj.us[is.na(mj.us$lon), -c(12:13)]
gc <- suppressMessages(geocode(paste(tgc$city, tgc$state.name, sep = ", "), "latlon"))
tgc[, c("lat", "lon")] <- gc[, c(2:1)]
mj.us <- as.data.frame(rbind(mj.us[!is.na(mj.us$lon), ], tgc))

## write data to file
mj.us <- mj.us[order(mj.us$date), ]
mj.us <- data.table(mj.us)
mj.us <- mj.us[, time := .GRP, by = "date"]
write.csv(mj.us, "./data/clean.csv", row.names = FALSE)
