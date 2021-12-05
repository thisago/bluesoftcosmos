## Main module of bluesoftcosmos

from std/httpclient import newAsyncHttpClient, close, getContent, newHttpHeaders
from std/strformat import fmt
import std/asyncdispatch
from std/xmltree import XmlNode, attr
from std/strutils import find, contains, strip, parseFloat, parseInt, replace,
                         AllChars, Digits, Letters, toLowerAscii

from pkg/scraper import findAll, text, attr, parseHtml
from pkg/useragent import mozilla

type
  Product* = object
    barcode*: int64
    name*: string
    image*: string
    mcn*: ProductMcn
    country*, owner*, distributors*: string
    category*: string
    brand*: Brand
    averagePrice*: AveragePrice # in R$
    prices*: seq[ProductPrice]
    related*: RelatedProducts
    commercialUnits*: seq[ProductUnits]
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
  AveragePrice* = tuple
    min, max: string
  Brand* = object
    name*, image*: string
  ProductUnits* = object
    barcode*: int64
    kind*: string
    packageQnt*, ballastQnt*, layerQnt*: int # How many units in in package
    length*, height*, width*: string
    grossWeight*, netWeight*: string


func getUrl(barcode: int64; baseUrl: string): string =
  fmt"{baseUrl}/products/{barcode}"

func parseMcn(mcn: string): ProductMcn =
  const search = " - "
  let i = mcn.find(search) - 1
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

func getAveragePrices(prices: seq[ProductPrice]): AveragePrice =
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
    product.name = productEl.findAll("a", {"title": "Click to see more information about the Product"}).text
    product.image = baseUrl & productEl.findAll("img").attr "src"
    product.barcode = productEl.findAll("span", {"class": "barcode"}).text.replace("Barcode:\n", "")
    if mcn.len > 0:
      product.mcn = mcn
    else:
      product.mcn = productEl.findAll("span", {"class": "ncm"}).text.replace("NCM:\n", "")

    result.add product

from std/xmltree import `$`

proc getProduct*(barcode: int64; tld = "io"): Future[Product] {.async.} =
  ## Fetches the product by bar code from Bluesoft Cosmos and extract it data
  let baseUrl = "https://cosmos.bluesoft." & tld
  let client = newAsyncHttpClient(headers = newHttpHeaders({
      "User-Agent": mozilla,
      "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
      "Cookie": "_cosmos_session=aVlQNmxiUzhjaTRIY1pjdjhPZUtjb1p1MFl6YlFsRTg5Ritra3ZYM0RrSFQzbDMreDJuVTZTN0JIaXJEZU4zcVUvWk9aSDkrT2hva0V2cGMraDVhUUdaYkFBMHRJZERvSnR6bGVsMC9STGkybFRGMzcvT0VJd2swaWhpUUNBU3pSajloeWpaV1d5ZURIc1lxeUF5dEpkMWpaM0w4S0RtQjJUcHlhZTlzZ2xCbTl1TEVGZTl3R01rN1pHdy9ZNnYvSkRJNlJwaGtET1czSWJnWUsxZ1NxTG8ycFJFWGpmZk9iN0c2R2ovQXptRWg3OWRMdHh6M00wUTlhamZYVVplQzZLbURaNlpKT2RzM0pQU1diNTgxeUx5YVJwNnh6NzI4dkhSVnExTVJPL3c9LS1HNW45NWhxcTI4M2VBV1Q3cjdIYW9BPT0%3D--e914512ac0c0a67f0ce40c4f5cf5f9528f97731d"
    }))
  var html: XmlNode
  try: html = parseHtml await client.getContent getUrl(barcode, baseUrl)
  except: return
  close client

  block basic:
    result.name = html.findAll("span", {"id": "product_description"}).text
    result.barcode = parseInt html.findAll("span", {"id": "product_gtin"}).text
    result.image = html.findAll([
      ("div", @{"id": "product-gallery"}),
      ("img", @{"class": ""}),
    ]).attr "src"
    if "https://" notin result.image:
      result.image = baseUrl & result.image
    result.brand.image =
      html.findAll("img", @{"class": "thumbnail img-full product-brand-picture"}).attr "src"
    result.mcn = parseMcn(
      html.findAll("span", @{"class": "description ncm-name label-figura-fiscal"}).text)
  block metadata:
    let
      meta = html.findAll("dl", {"class": "dl-horizontal"})[0]
      keys = meta.findAll("dt")
      values = meta.findAll("dd", {"class": "description"})
    for i, k in keys:
      let
        key = k.text.strip(chars = AllChars - Letters).toLowerAscii
        value = values[i].text
      case key:
      of "country": result.country = value
      of "owner": result.owner = value
      of "distributors": result.distributors = value
      of "brand": result.brand.name = value

  block prices:
    for el in html.findAll([
      ("div", @{"id": "price-boxes"}),
      ("div", @{"_": ""}),
    ]):
      if "well price-box" in el.attr "class":
        let priceBox = extractPriceBox el
        result.prices.add priceBox
    result.averagePrice = getAveragePrices result.prices
  block related:
    let relatedEls = html.findAll("div", {"class": "product-list"})
    result.related.mcn = getRelatedProducts(relatedEls[0], result.mcn.code, baseUrl)
    result.related.category = getRelatedProducts(relatedEls[1], baseUrl = baseUrl)
  block commercialUnits:
    for row in html.findAll("table", {"class": "table table-striped table-responsive"})[0].
                    findAll "tr":
      var units: ProductUnits
      let values = row.findAll "td"
      if values.len > 0:
        try:
          units.barcode = int64 parseInt values[0].text
          units.kind = values[1].text
          units.packageQnt = parseInt values[2].text
          units.ballastQnt = parseInt values[3].text
          units.layerQnt = parseInt values[4].text
          units.length = values[5].text
          units.height = values[6].text
          units.width = values[7].text
          units.grossWeight = values[8].text
          units.netWeight = values[9].text

          result.commercialUnits.add units
        except:
          discard

when isMainModule:
  from std/strutils import multiReplace
  let product = waitFor getProduct 7896200031158
  echo multiReplace($product, {
    "), (": "), \n  (",
    ", (": ", \n  (",
    ")], ": ")],\n"
  })
