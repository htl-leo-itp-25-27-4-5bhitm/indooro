fetch('http://localhost:8080/api/products?size=100')
  .then(res => res.json())
  .then(data => console.log(data));


  // Produkte suchen
fetch('http://localhost:8080/api/products/search?q=apfel&size=10')
  .then(res => res.json())
  .then(data => console.log(data));