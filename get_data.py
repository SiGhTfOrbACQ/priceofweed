# -*- coding: utf-8 -*-

import requests
from bs4 import BeautifulSoup
import pandas as pd

def parse_table(soup, df):
    table = soup.find("table")
    for row in table.find_all("tr")[1:]:
        data = list(row.find_all("td"))
        for i in range(len(data)):
           data[i] = data[i].get_text(strip = True)
        df.append(data)
    return df

df = []
url = "http://www.priceofweed.com/data/all?pg=1"
while True:
    soup = BeautifulSoup(requests.get(url).content)
    df = parse_table(soup, df)
    try:
        url = soup.find("div", id = "pagination").find("a", text = "Next")["href"]
    except:
        break

df = pd.DataFrame(df, columns = ["location", "price", "amount", "quality", "date"])
df.to_csv("./data/mj_raw.csv", na_rep = "NA", index = False, encoding = "utf-8")
