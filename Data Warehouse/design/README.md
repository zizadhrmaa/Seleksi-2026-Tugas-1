# Diagram Design

File `.dot` merupakan source diagram. PNG pada folder ini dihasilkan dari source tersebut menggunakan Graphviz.

```powershell
dot -Tpng -Gdpi=150 .\erd.dot -o .\erd.png
dot -Tpng -Gdpi=150 .\relational_diagram.dot -o .\relational_diagram.png
```

`erd.png` menampilkan entity, atribut, key, relationship set, cardinality, dan participation. `relational_diagram.png` menampilkan implementasi relation lengkap dengan tipe data dan foreign key sesuai `src/01_create_warehouse.sql`.
