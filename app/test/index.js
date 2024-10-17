a = ["apple", "banana", "pear"]

console.log("Hello World")

function captureInput() {
  var ul = document.getElementById("search")
  if(ul != null) {
    ul.remove()
  }
  var newUl = document.createElement("li")
  newUl.id = "search"
  var x = document.getElementById("input").value;
  for (let i = 0; i < a.length; i++) {
    if(x.length > 0 && a[i].includes(x)) {
      var el = document.createElement("ul")
      el.innerHTML = a[i]
      newUl.appendChild(el)
    }
  }
  document.getElementById("searchBox").appendChild(newUl)
  console.log(newUl)
}