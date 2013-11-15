repo: clean_data.Rout plot_data.Rout

# ./data/raw.csv: get_data.py
# 	test -d "data" || mkdir -p "data"
# 	python get_data.py

./data/clean.csv: clean_data.R ./data/raw.csv
	R CMD BATCH clean_data.R

plot_data.Rout: plot.R ./data/clean.csv
	R CMD BATCH plot_data.R
