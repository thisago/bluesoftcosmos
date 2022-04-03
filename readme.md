# bluesoftcosmos

Bluesoft Cosmos extractor

Bluesoft Cosmos is online catalog that allows search products by barcode

This website [sells an API access](https://cosmos.bluesoft.io/api-pricings) to get some of these data, but the API doens't provides all data of website frontend.

## Extracted data

- Barcode (the provided code)
- Product name
- Product image
- MCN (Mercosur Common Nomenclature)
- Register country
- Brand
  - Name
  - Image
- Category
- Average price
- Medium price
  - Min
  - Max
- Prices (seq of object)
  - State
  - Smaller price
  - Larger price
  - Medium price
  - Most common price
  - Searches (based in how many searches)
- Same MCN products (seq of object)
  - Product name
  - Image
  - Code
- Same categories products (seq of object)
  - Product name
  - Image
  - Code
- Price history
  - Maximum (tuple of price and time)
  - Minimum (tuple of price and time)
- seq of ProductUnits
  - Barcode
  - Kind
  - PackageQnt
  - BallastQnt
  - LayerQnt
  - Length
  - Height
  - Width
  - GrossWeight
  - NetWeight

## TODO

- [x] Extract package width, height, weight
- [ ] Extract MCN comments
- [ ] Fix related products extraction. It needs to be name based not index based

## License

GPL-3
