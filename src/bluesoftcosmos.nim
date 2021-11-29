## Main module of bluesoftcosmos

from std/httpclient import newAsyncHttpClient, close, getContent, newHttpHeaders
from std/strformat import fmt
import std/asyncdispatch
from std/xmltree import XmlNode, attr
from std/strutils import find, contains, strip, parseFloat, multiReplace,
                         parseInt, replace

import pkg/scraper
from pkg/useragent import mozilla

type
  Product* = object
    barcode*: string
    name*: string
    image*, brandImage*: string
    mcn*: ProductMcn
    country*, owner*, brand*, distributors*: string
    category*: string
    averagePrice*: AveragePrice # in R$
    prices*: seq[ProductPrice]
    related*: RelatedProducts
  ProductPrice* = object
    state*: string
    minPrice*, mediumPrice*, maxPrice*, commonPrice*: float
    searches: int
  RelatedProducts* = object
    mcn*, category*: seq[RelatedProduct]
  RelatedProduct* = object
    name*, image*, mcn*, barcode*: string
  ProductMcn* = tuple
    id, name: string
  AveragePrice* = tuple
    min, max: float

const baseUrl = "https://cosmos.bluesoft.io"

func getUrl(barcode: string): string =
  fmt"{baseUrl}/products/{barcode}"

func parseMcn(mcn: string): ProductMcn =
  const search = " - "
  let i = mcn.find(search) - 1
  result.id = mcn[0..i]
  result.name = mcn[(i + search.len + 1)..^1]

func parseBRL(s: string): float =
  result = parseFloat s.multiReplace({
    "R$": "",
    ",": "."
  }).strip

func extractPriceBox(el: XmlNode): ProductPrice =
  result.state = el.findAll("h4").text
  let datas = el.findAll([
    ("dl", @{"class": "dl-horizontal"}),
    ("dd", @{"class": "description"}),
  ])
  result.minPrice = parseBRL datas[0].text
  result.mediumPrice = parseBRL datas[1].text
  result.maxPrice = parseBRL datas[2].text
  result.commonPrice = parseBRL datas[3].text
  result.searches = parseInt datas[4].text

func getAveragePrices(prices: seq[ProductPrice]): AveragePrice =
  result.min = prices[0].minPrice
  for price in prices:
    if price.minPrice < result.min:
      result.min = price.minPrice
    if price.maxPrice > result.max:
      result.max = price.maxPrice

func getRelatedProducts(el: XmlNode; mcn = ""): seq[RelatedProduct] =
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

proc getProduct*(barcode: string): Future[Product] {.async.} =
  ## Fetches the product by bar code from Bluesoft Cosmos and extract it data
  let client = newAsyncHttpClient(headers = newHttpHeaders({
      "User-Agent": mozilla,
      "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
      "User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:78.0) Gecko/20100101 Firefox/78.0",
      "Accept-Language": "en-US,en;q=0.5",
    }))
  var html: XmlNode
  try: html = parseHtml await client.getContent getUrl barcode
  except: return
  close client

  block basic:
    result.name = html.findAll("span", {"id": "product_description"}).text
    result.barcode = html.findAll("span", {"id": "product_gtin"}).text
    result.image = baseUrl & html.findAll([
      ("div", @{"id": "product-gallery"}),
      ("img", @{"class": ""}),
    ]).attr "src"
    result.brandImage =
      html.findAll("img", @{"class": "thumbnail img-full product-brand-picture"}).attr "src"
    result.mcn = parseMcn(
      html.findAll("span", @{"class": "description ncm-name label-figura-fiscal"}).text)
  block meta:
    let metas = html.findAll([
      ("dl", @{"class": "dl-horizontal"}),
      ("dd", @{"class": "description"}),
    ])
    result.country = metas[0].text
    result.owner = metas[1].text
    result.distributors = metas[2].text
    result.category = metas[3].text
    result.brand = metas[4].text
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
    result.related.mcn = getRelatedProducts(relatedEls[0], result.mcn.id)
    result.related.category = getRelatedProducts relatedEls[1]

when isMainModule:
  let product = waitFor getProduct "7891000277072"
  echo multiReplace($product, {
    "), (": "), \n  (",
    ", (": ", \n  (",
    ")], ": ")],\n"
  })
