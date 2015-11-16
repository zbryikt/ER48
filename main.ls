require! <[fs cheerio request bluebird]>

Qs = <[
  099Q1 099Q2 099Q3 099Q4 100Q1 100Q2 100Q3 100Q4 101Q1
  101Q2 101Q3 101Q4 102Q1 102Q2 102Q3 102Q4 103Q1 103Q2
  103Q3 103Q4 104Q1
]>

jar = request.jar!

init = -> new bluebird (res, rej) ->
  (e,r,b) <- request {
    url: \http://www.nhi.gov.tw/AmountInfoWeb/N_iDesc.aspx?rtype=6&Q5C2_ID=999
    jar, method: \GET
  }, _
  res!

fetch = (urlp, time = "10408", htype = "", page = 1, data = {}) -> new bluebird (res, rej) ->
  formData = {} <<< data
  if formData.__VIEWSTATE =>
    formData.__EVENTTARGET = \ctl00$ContentPlaceHolder1$GV_List
    formData.__EVENTARGUMENT = "Page$#page"
  params = do
    YYQN: time #10408
    Branch: ""
    AreaID: ""
    Special: htype
    Hosp_Name: ""
    Hosp_ID: ""
    PageNum: 99
    Q5C1_ID: 2
    Q5C2_ID: 1652
    IsMap: ""
  paramstring = ["#k=#v" for k,v of params].join(\&)
  urlp = "#url?#paramstring"
  (e,r,b) <- request {
    url: urlp
    jar
    method: \POST
    formData

  }, _
  $ = cheerio.load(b)
  fs.write-file-sync \out.html, b
  ret = []
  trs = $('tr td[colspan=4] table tr')
  trs.splice 0, 1
  if $(trs[trs.length - 1]).find(\td).length == 3 => trs.splice trs.length - 1, 1
  x = 0
  for tr in trs =>
    tr = $(tr)
    data = {}
      ..section  = tr.find("td:nth-of-type(2) span").text!trim!
      ..county   = tr.find("td:nth-of-type(3) span").text!trim!
      ..code     = tr.find("td:nth-of-type(4)").text!trim!
      ..name     = tr.find("td:nth-of-type(5) span").text!trim!
      ..site-idx = tr.find("td:nth-of-type(6) span").text!trim!
      ..sect-idx = tr.find("td:nth-of-type(7) span").text!trim!
      ..all-idx  = tr.find("td:nth-of-type(8) span").text!trim!
    if htype => data.type = <[醫學中心 區域醫院 地區醫院 基層診所]>[htype - 1]
    #if x == 0 =>
    #  x = 1
    #  console.log data.section, data.name
    if data.section => ret.push data
  console.log "#{ret.length} item parsed."
  inputs = $('input')
  list = []
  data = {}
  for inp in inputs =>
    [name, value] = [$(inp).attr(\name), $(inp).val!]
    #if name? and name and value? => data[name] = value
    if name? and name and value? and $(inp).attr(\type) == \hidden => data[name] = value
  data[\ctl00$ContentPlaceHolder1$PageNum] = 99
  next = 1
  #data.__EVENTTARGET = \ctl00$ContentPlaceHolder1$GV_List
  #data.__EVENTARGUMENT = "Page$#next"
  pagenum = $("tr td[colspan=8] tr td").length
  curpage = $("tr td[colspan=8] tr span").text!
  res {pagenum, ret, data}

result = []

fin = ->
  fs.write-file-sync \output.json, JSON.stringify(result)

next = (qidx = 0, htype = 1, page = 1, data = {}) ->
  Q = Qs[qidx]
  console.log "fetch #Q #page / #htype ... ( #{parseInt(100 * qidx / Qs.length)}% )"
  (payload) <- fetch url, Q, htype, page, data .then
  data <<< payload.data
  result := result ++ payload.ret
  if page < payload.pagenum => page += 1
  else =>
    page := 1
    data := {}
    if htype < 4 => htype := htype + 1
    else =>
      htype := 1
      data := {}
      if qidx < Qs.length - 1 => qidx := qidx + 1
      else => return fin!
  next qidx, htype, page, data

url = \http://www.nhi.gov.tw/AmountInfoWeb/N_Query15S.aspx
url = \http://www.nhi.gov.tw/AmountInfoWeb/search.aspx
<- init!then
console.log "initialized."
next!
