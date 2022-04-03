## Main module of bluesoftcosmos

from std/httpclient import newAsyncHttpClient, close, get, newHttpHeaders, body
from std/strformat import fmt
import std/asyncdispatch
from std/xmltree import XmlNode, attr
from std/strutils import find, contains, strip, parseFloat, parseInt, replace,
                         AllChars, Digits

from pkg/scraper import findAll, attr, parseHtml
# from pkg/useragent import mozilla

type
  Product* = object
    barcode*: int64
    name*: string
    image*: string
    mcn*: ProductMcn
    country*, owner*, distributors*: string
    category*: string
    averagePrice: string
    brand*: Brand
    mediumPrice*: MediumPrice # in R$
    prices*: seq[ProductPrice]
    related*: RelatedProducts
  ProductPrice* = object
    state*: string
    minPrice*, mediumPrice*, maxPrice*, commonPrice*: string
    searches: int
  RelatedProducts* = object
    mcn*, category*: seq[RelatedProduct]
  RelatedProduct* = object
    name*, image*, mcn*, barcode*: string
  ProductMcn* = tuple
    code, description: string
  MediumPrice* = tuple
    min, max: string
  Brand* = object
    name*, image*: string

func text(node: XmlNode): string =
  result = scraper.text node
  if result in ["Unknown", "Não informado"]:
    result = ""

func text(nodes: openArray[XmlNode]): string =
  if nodes.len > 0:
    result = nodes[0].text

func getUrl(barcode: int64; baseUrl, tld: string): string =
  var product = "product"
  if tld == "com.br":
    product = "produto"
  fmt"{baseUrl}/{product}/{barcode}"

func parseMcn(mcn: string): ProductMcn =
  const search = " - "
  let i = mcn.find(search) - 1
  if i >= 0:
    result.code = mcn[0..i]
    result.description = mcn[(i + search.len + 1)..^1]

func parseCurrency(s: string): float =
  result = parseFloat s.strip(chars = AllChars - Digits).replace(",", ".")

func extractPriceBox(el: XmlNode): ProductPrice =
  result.state = el.findAll("h4").text
  let datas = el.findAll([
    ("dl", @{"class": "dl-horizontal"}),
    ("dd", @{"class": "description"}),
  ])
  result.minPrice = datas[0].text
  result.mediumPrice = datas[1].text
  result.maxPrice = datas[2].text
  result.commonPrice = datas[3].text
  result.searches = parseInt datas[4].text

func getMediumPrices(prices: seq[ProductPrice]): MediumPrice =
  if prices.len > 0:
    result.min = prices[0].minPrice
    result.max = prices[0].maxPrice
    for price in prices:
      let
        minPrice = parseCurrency price.minPrice
        maxPrice = parseCurrency price.maxPrice
      if minPrice < parseCurrency result.min:
        result.min = price.minPrice
      if maxPrice > parseCurrency result.max:
        result.max = price.maxPrice

func getRelatedProducts(el: XmlNode; mcn = ""; baseUrl: string): seq[RelatedProduct] =
  for productEl in el.findAll("li", {"class": "product-list-item col-xs-12 col-lg-3 col-md-4"}):
    var product: RelatedProduct
    product.name = productEl.findAll(@[
      ("h5", @{"class": "description"}),
      ("a", @{:})
    ]).text
    product.image = productEl.findAll("img").attr "src"
    if product.image.len > 0:
      product.image = baseUrl & product.image
      
    product.barcode = productEl.findAll("span", {"class": "barcode"}).text.replace("Barcode:\n", "")
    if mcn.len > 0:
      product.mcn = mcn
    else:
      product.mcn = productEl.findAll("span", {"class": "ncm"}).text.replace("NCM:\n", "")

    result.add product

proc getProduct*(barcode: int64; tld = "com.br"): Future[Product] {.async.} =
  ## Fetches the product by bar code from Bluesoft Cosmos and extract it data
  let baseUrl = "https://cosmos.bluesoft." & tld
  let client = newAsyncHttpClient(headers = newHttpHeaders({
      # "User-Agent": mozilla,
      "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
      "User-Agent": "mozilla/5.0 (X11; Linux x86_64; rv:78.0) Gecko/20100101 Firefox/78.0",
    }))
  var html: XmlNode
  let resp = await client.get getUrl(barcode, baseUrl, tld)
  try: html = parseHtml await resp.body
  except: return
  close client

  block basic:
    result.name = html.findAll("span", {"id": "product_description"}).text
    result.barcode = parseInt html.findAll("span", {"id": "product_gtin"}).text
    result.image = html.findAll([
      ("div", @{"id": "product-gallery"}),
      ("img", @{"class": ""}),
    ]).attr "src"
    if result.image.len > 0:
      result.image = baseUrl & result.image
    result.brand.image =
      html.findAll("img", @{"class": "thumbnail img-full product-brand-picture"}).attr "src"
    result.mcn = parseMcn(
      html.findAll("span", @{"class": "description ncm-name label-figura-fiscal"}).text)
  block meta:
    let metasEl = html.findAll("dl", @{"class": "dl-horizontal"})
    if metasEl.len > 0:
      let
        metasTitle = metasEl[0].findAll("dt")
        metasData = metasEl[0].findAll("dd", @{"class": "description"})
      for i, title in metasTitle:
        template val: string = metasData[i].text
        case title.text[0..^2]:
        of "Country", "País de Registro": result.country = val
        of "Owner", "Fabricante": result.owner = val
        of "Distributors", "Distribuidores": result.distributors = val
        of "Brand", "Marca": result.brand.name = val
        of "Average Price", "Preço Médio": result.averagePrice = val
        of "Category", "Categoria": result.category = val
  block prices:
    for el in html.findAll([
      ("div", @{"id": "price-boxes"}),
      ("div", @{"_": ""}),
    ]):
      if "well price-box" in el.attr "class":
        let priceBox = extractPriceBox el
        result.prices.add priceBox
    result.mediumPrice = getMediumPrices result.prices
  block related:
    let relatedEls = html.findAll("div", {"class": "product-list"})
    if relatedEls.len > 0:
      result.related.mcn = getRelatedProducts(relatedEls[0], result.mcn.code, baseUrl)
      if relatedEls.len > 1:
        result.related.category = getRelatedProducts(relatedEls[1], baseUrl = baseUrl)

when isMainModule:
  from std/strutils import multiReplace
  when true:
    const codes = []
    for code in codes:
      try:
        let product = waitFor getProduct code
        echo multiReplace($product, {
          "), (": "), \n  (",
          ", (": ", \n  (",
          ")], ": ")],\n",
        })
      except:
        quit $code
  else:
    let product = waitFor getProduct 7896080900148
    echo multiReplace($product, {
      "), (": "), \n  (",
      ", (": ", \n  (",
      ")], ": ")],\n",
    })
