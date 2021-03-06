# Changelog

## Version 1.5.0 (2022/04/03)

- Fixed the meta extraction
- Fixed the related products name extraction
- Added meta averagePrice
- Changed default tld to "com.br"
- Fixed medium price crash when no prices provided
- Fixed another crash in related products extraction
- Fixed crash in meta extraction when no meta container is sent
- If value is "Unknown" then set to a blank string
- If there's no image, then set to a blank string, not to the Bluesoft site

---

## Version 1.4.3 (02/23/2022)

- Changed the `products` route to `product`

---

## Version 1.4.2 (12/7/2021)

- Fixed url generation

---

## Version 1.4.1 (12/7/2021)

- Now the `getProduct` throw an error if connection with Bluesoft Cosmos server not succeeds

---

## Version 1.4.0 (12/7/2021)

- Average price metadata
- Added a verification to not fall in products (like [7897888860269](https://cosmos.bluesoft.io/products/7897888860269)) that doesn't have the prices searches

---

## Version 1.3.0 (12/1/2021)

- Added width, height, weight

---

## Version 1.2.0 (12/1/2021)

- Fixed metadata extraction
- Fixed image extraction

---

## Version 1.1.0 (12/1/2021)

- Barcode is now a `int64`

---

## Version 1.0.0 (11/30/2021)

- Based in the [paid API spec](https://cosmos.bluesoft.io/api), the structure of data was changed
- Fixed license typo
- In order to handle the BRL and USD currency, the price is not float anymore,
  but string
- Removed useless imports
- Added possibility to change base url to select language (`.io` is english and `.com.br` is portuguese)
- Added tests
