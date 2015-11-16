require! <[fs]>

data = JSON.parse(fs.read-file-sync \output.json .toString!)

for item in data =>
  list = <[section county code name siteIdx sectIdx allIdx type]>.map -> item[it]
  console.log list.join(\,)
