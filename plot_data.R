pkgs <- c("ggplot2", "lubridate", "plyr", "grid", "sp", "maps", "maptools", "mapproj", "scales", "reshape2")
invisible(lapply(pkgs, require, character.only = TRUE))

basic.theme <- function()
  theme_bw() + theme(plot.margin = unit(rep(.05, 4), "in"))

map.theme <- function() {
  theme_bw() + theme(axis.line = element_blank(),
                     axis.text.x = element_blank(), axis.text.y = element_blank(),
                     axis.title.x = element_blank(), axis.title.y = element_blank(),
                     axis.ticks = element_blank(), panel.border = element_blank(),
                     panel.grid.major = element_blank(), plot.margin = unit(rep(.1, 4), "in"))
}

## plot transaction density over space and time
mj.us$year <- year(mj.us$date)
attributes(mj.us$quality)$levels <- c("low quality", "medium quality", "high quality")
mj.state <- ddply(mj.us, .(state.name, year, quality), nrow)
colnames(mj.state) <- c("state", "year", "quality", "obs")
density.map <- na.omit(merge(us.map, mj.state, sort = FALSE, by = "state", all.x = TRUE))
density.map <- density.map[order(density.map$order), ]
density.map$obs <- cut(density.map$obs, dig.lab = 0,
                       breaks = quantile(density.map$obs, probs = c(0, .025, .25, .5, .75, .975, 1)))
density.map$obs <- ordered(density.map$obs, labels = c("5 or less", "40 or less", "100 or less",
                                              "400 or less", "2000 or less", "4000 or less"))
p <- ggplot(data = density.map, aes(x = long, y = lat, group = group, fill = obs))
p <- p + geom_polygon()
p <- p + facet_grid(year ~ quality)
p <- p + borders("state", colour = "black", size = .25)
p <- p + scale_fill_brewer("Number of\nTransactions")
p <- p + coord_map("albers", 29.5, 45.5)
p <- p + map.theme()
ggsave("./figures/density_map.png", plot = p, height = 4, width = 7, dpi = 600)
attributes(mj.us$quality)$levels <- c("low", "medium", "high")

## plot transaction density over time
submit <- ddply(mj.us, .(date), summarize, obs = length(ppg))
submit$date <- as.Date(submit$date, format = "%Y-%m-%d")
p <- ggplot(submit, aes(x = date, y = obs))
p <- p + geom_point(size = 1.5)
p <- p + stat_smooth(method = "loess", span = 1.5)
p <- p + scale_x_date(labels = date_format("%Y"), breaks = date_breaks("1 year"))
p <- p + labs(x = NULL, y = "Submissions per Day")
p <- p + basic.theme()
ggsave("./figures/submit.png", plot = p, width = 8.25, height = 3.3, dpi = 600)
