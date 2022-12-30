from bs4 import BeautifulSoup
import pandas as pd
import requests as re

url = "https://www.timeforpickleball.com/Locations.html"
resp = re.get(url)
soup = BeautifulSoup(resp.text, 'html.parser')

data = []

for title in soup.find_all('h3', {'class': 'wsite-content-title'}):
  contents = title.find_next('div')
  info = contents.find_all('i')
  keys = ['Name']
  values = [title.text.replace('\n', '').replace('\r', '').replace('â', '').strip()]
  for i in info:
    try:
      keys.append(i["aria-label"].replace('\n', '').strip())
    except:
      print('error')
  info2 = contents.select('tr > td')
  for i in info2[1::2]:
    values.append(i.text.replace('\n', '').replace('\r', '').strip())
  data.append(dict(zip(keys, values)))

pd.DataFrame(data).to_csv('data/data.csv')