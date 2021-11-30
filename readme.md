# bluesoftcosmos

Bluesoft Cosmos extractor

Bluesoft Cosmos is online catalog that allows search products by barcode

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
- Medium price
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

## TODO

- [ ] Extract package width, height, weight

## License

GPL-3
