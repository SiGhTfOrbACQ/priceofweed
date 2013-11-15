repo: data.Rout plot.Rout

# ./data/mj_raw.csv: price_data.py #data is no longer accessible
# 	test -d "data" || mkdir -p "data"
# 	python price_data.py

./data/mj_clean.csv: data.R ./data/mj_raw.csv
	R CMD BATCH data.R

plot.Rout: plot.R ./data/mj_clean.csv
	R CMD BATCH plot.R
