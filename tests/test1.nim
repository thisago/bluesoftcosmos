import std/unittest
from std/asyncdispatch import waitFor
from std/strutils import contains

from bluesoftcosmos import getProduct

let product = waitFor getProduct(7891000277072, "com.br")
echo product

suite "bluesoftcosmos":
  test "Name": require product.name == "CHOCOLATE AO LEITE CRUNCH PACOTE 90G"
  test "Image": require product.image.contains "/assets/ncm/IV-2409d8da52fe4e7872b64988b2feca0a.png"
  test "MCN":
    require product.mcn.code == "1806.32.10"
    require product.mcn.description == "Cacau e suas preparações - Chocolate e outras preparações alimentícias que contenham cacau. - Outros, em tabletes, barras e paus: - Não recheados - Chocolate"
  test "Country": require product.country == "Brasil"
  test "Owner": require product.owner == "Não informado"
  test "Distributors": require product.distributors == "Não informado"
  test "Category": require product.category == "Chocolate"
  test "Brand":
    require product.brand.name == "CRUNCH"
    require product.brand.image.contains "/brands/brand_crunch"
  test "Average price":
    require product.averagePrice.min == "R$ 3,50"
    require product.averagePrice.max == "R$ 11,00"
