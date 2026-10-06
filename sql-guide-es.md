# Repaso rápido de SQL

🇬🇧 [English version](sql-guide.md)

📂 También disponible en [un fichero por sección](sections/es/README.md)

## Cómo leer este documento

Cada sección lleva su **nivel** y su **importancia**:

| Nivel            | Importancia                                         |
|------------------|-----------------------------------------------------|
| 🟢 Básico        | ⭐⭐⭐ Imprescindible: se usa a diario               |
| 🟡 Intermedio    | ⭐⭐ Muy útil: aparece a menudo en el trabajo real   |
| 🔴 Avanzado      | ⭐ Conviene conocerlo: casos concretos o más teoría  |

Las secciones 1–13 son la **base**. Las 14–23 son la **ampliación**, ordenadas de más fácil a más difícil (y, dentro del mismo nivel, de más a menos importante). La 24 son **ejercicios** para comprobar lo aprendido.

**Base**
1. Crear y modificar tablas · 🟢 ⭐⭐⭐
2. INSERT, UPDATE, DELETE · 🟢 ⭐⭐⭐
3. SELECT básico · 🟢 ⭐⭐⭐
4. WHERE, LIKE y filtros · 🟢 ⭐⭐⭐
5. ORDER BY y LIMIT · 🟢 ⭐⭐⭐
6. Agregación y GROUP BY · 🟢 ⭐⭐⭐
7. JOINs · 🟡 ⭐⭐⭐
8. Subconsultas · 🟡 ⭐⭐⭐
9. UNION, INTERSECT, EXCEPT · 🟡 ⭐⭐
10. Funciones útiles · 🟢 ⭐⭐
11. Índices y vistas (lo justo) · 🟡 ⭐⭐
12. Transacciones · 🟡 ⭐⭐⭐
13. Procedimientos almacenados · 🟡 ⭐⭐

**Ampliación**

14. Trampas con NULL · 🟢 ⭐⭐⭐
15. Restricciones (constraints) a fondo · 🟢 ⭐⭐⭐
16. Normalización · 🟢 ⭐⭐
17. Funciones de ventana · 🟡 ⭐⭐⭐
18. UPSERT (insertar o actualizar) · 🟡 ⭐⭐
19. Triggers · 🟡 ⭐⭐
20. Usuarios y permisos · 🟡 ⭐
21. CTE recursivas · 🔴 ⭐⭐
22. Índices a fondo y EXPLAIN · 🔴 ⭐⭐
23. Aislamiento de transacciones y ACID · 🔴 ⭐

**Práctica**

24. Ejercicios con solución · 🟢🟡🔴

---

Todos los ejemplos usan estas dos tablas:

```sql
-- clientes(id, nombre, email, ciudad, fecha_alta)
-- pedidos(id, cliente_id, producto, importe, fecha)
```

---

## 1. Crear y modificar tablas (DDL) · 🟢 ⭐⭐⭐

```sql
CREATE TABLE clientes (
    id          INT PRIMARY KEY,
    nombre      VARCHAR(100) NOT NULL,
    email       VARCHAR(150) UNIQUE,
    ciudad      VARCHAR(50),
    fecha_alta  DATE DEFAULT CURRENT_DATE
);

CREATE TABLE pedidos (
    id          INT PRIMARY KEY,
    cliente_id  INT REFERENCES clientes(id),   -- clave foránea
    producto    VARCHAR(100),
    importe     DECIMAL(10,2),
    fecha       DATE
);

ALTER TABLE clientes ADD COLUMN telefono VARCHAR(20);   -- añadir columna
ALTER TABLE clientes DROP COLUMN telefono;              -- quitar columna

DROP TABLE pedidos;        -- borra la tabla entera (estructura + datos)
TRUNCATE TABLE pedidos;    -- vacía la tabla pero la deja creada
```

---

## 2. INSERT, UPDATE, DELETE (DML) · 🟢 ⭐⭐⭐

### INSERT

```sql
-- Una fila
INSERT INTO clientes (id, nombre, email, ciudad)
VALUES (1, 'Ana', 'ana@mail.com', 'Madrid');

-- Varias filas a la vez
INSERT INTO clientes (id, nombre, ciudad) VALUES
    (2, 'Luis',  'Sevilla'),
    (3, 'Marta', 'Madrid');

-- Insertar a partir de un SELECT
INSERT INTO clientes_madrid (id, nombre)
SELECT id, nombre FROM clientes WHERE ciudad = 'Madrid';
```

### UPDATE

```sql
UPDATE clientes
SET ciudad = 'Barcelona', email = 'luis@mail.com'
WHERE id = 2;
```

> ⚠️ Sin `WHERE`, el `UPDATE` afecta a **todas** las filas.

### DELETE

```sql
DELETE FROM pedidos WHERE fecha < '2024-01-01';
```

> ⚠️ Igual: sin `WHERE` borra todo.

---

## 3. SELECT básico · 🟢 ⭐⭐⭐

```sql
SELECT * FROM clientes;                         -- todas las columnas
SELECT nombre, ciudad FROM clientes;            -- columnas concretas
SELECT nombre AS cliente FROM clientes;         -- alias de columna
SELECT DISTINCT ciudad FROM clientes;           -- sin repetidos
```

### Orden lógico de un SELECT

```sql
SELECT    columnas
FROM      tabla
WHERE     filtro de filas
GROUP BY  agrupación
HAVING    filtro de grupos
ORDER BY  orden
LIMIT     n;
```

(Se escribe en ese orden; se *ejecuta* aproximadamente como FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT. Por eso no puedes usar un alias del SELECT dentro del WHERE.)

---

## 4. WHERE y operadores de filtrado · 🟢 ⭐⭐⭐

```sql
-- Comparación: =, <>, !=, <, >, <=, >=
SELECT * FROM pedidos WHERE importe >= 100;

-- AND / OR / NOT
SELECT * FROM clientes WHERE ciudad = 'Madrid' AND fecha_alta > '2025-01-01';
SELECT * FROM clientes WHERE NOT ciudad = 'Madrid';

-- BETWEEN (incluye los extremos)
SELECT * FROM pedidos WHERE importe BETWEEN 50 AND 200;

-- IN / NOT IN
SELECT * FROM clientes WHERE ciudad IN ('Madrid', 'Sevilla', 'Valencia');

-- NULL (¡no se usa = NULL!)
SELECT * FROM clientes WHERE email IS NULL;
SELECT * FROM clientes WHERE email IS NOT NULL;
```

### LIKE (patrones de texto)

| Comodín | Significa                  |
|---------|----------------------------|
| `%`     | cero o más caracteres      |
| `_`     | exactamente un carácter    |

```sql
SELECT * FROM clientes WHERE nombre LIKE 'A%';      -- empieza por A
SELECT * FROM clientes WHERE nombre LIKE '%ez';     -- termina en "ez"
SELECT * FROM clientes WHERE email  LIKE '%gmail%'; -- contiene "gmail"
SELECT * FROM clientes WHERE nombre LIKE '_a%';     -- 2ª letra es "a"
SELECT * FROM clientes WHERE nombre NOT LIKE 'A%';

-- Sin distinguir mayúsculas
SELECT * FROM clientes WHERE LOWER(nombre) LIKE 'ana%';
SELECT * FROM clientes WHERE nombre ILIKE 'ana%';   -- solo PostgreSQL
```

---

## 5. ORDER BY y LIMIT · 🟢 ⭐⭐⭐

```sql
SELECT * FROM pedidos ORDER BY importe DESC;            -- mayor a menor
SELECT * FROM clientes ORDER BY ciudad ASC, nombre;     -- varios criterios

SELECT * FROM pedidos ORDER BY importe DESC LIMIT 5;    -- top 5 (MySQL, PostgreSQL, SQLite)
SELECT * FROM pedidos ORDER BY fecha LIMIT 10 OFFSET 20; -- paginación

SELECT TOP 5 * FROM pedidos ORDER BY importe DESC;      -- equivalente en SQL Server
```

---

## 6. Funciones de agregación y GROUP BY · 🟢 ⭐⭐⭐

```sql
SELECT COUNT(*)        FROM pedidos;          -- nº de filas
SELECT COUNT(email)    FROM clientes;         -- nº de valores NO nulos
SELECT SUM(importe)    FROM pedidos;
SELECT AVG(importe)    FROM pedidos;
SELECT MIN(importe), MAX(importe) FROM pedidos;
```

### GROUP BY

```sql
-- Total gastado por cliente
SELECT cliente_id, SUM(importe) AS total
FROM pedidos
GROUP BY cliente_id;

-- Clientes por ciudad
SELECT ciudad, COUNT(*) AS num_clientes
FROM clientes
GROUP BY ciudad
ORDER BY num_clientes DESC;
```

> Regla: toda columna del `SELECT` que no esté dentro de una función de agregación tiene que estar en el `GROUP BY`.

### HAVING (filtrar grupos)

```sql
-- Clientes que han gastado más de 500
SELECT cliente_id, SUM(importe) AS total
FROM pedidos
GROUP BY cliente_id
HAVING SUM(importe) > 500;
```

**WHERE vs HAVING:** `WHERE` filtra filas *antes* de agrupar; `HAVING` filtra grupos *después*.

---

## 7. JOINs · 🟡 ⭐⭐⭐

Combinan filas de varias tablas según una condición.

```
clientes                 pedidos
+----+-------+          +----+------------+---------+
| id | nombre|          | id | cliente_id | importe |
+----+-------+          +----+------------+---------+
| 1  | Ana   |          | 10 | 1          | 50      |
| 2  | Luis  |          | 11 | 1          | 30      |
| 3  | Marta |          | 12 | 2          | 80      |
+----+-------+          | 13 | 99         | 20      |  <- cliente inexistente
                        +----+------------+---------+
```

### INNER JOIN — solo las filas que coinciden en ambas

```sql
SELECT c.nombre, p.importe
FROM clientes c
INNER JOIN pedidos p ON p.cliente_id = c.id;
-- Ana 50, Ana 30, Luis 80   (Marta no sale, el pedido 13 tampoco)
```

`JOIN` a secas = `INNER JOIN`.

### LEFT JOIN — todas las de la izquierda, aunque no tengan pareja

```sql
SELECT c.nombre, p.importe
FROM clientes c
LEFT JOIN pedidos p ON p.cliente_id = c.id;
-- Ana 50, Ana 30, Luis 80, Marta NULL
```

Truco típico — clientes **sin** pedidos:

```sql
SELECT c.nombre
FROM clientes c
LEFT JOIN pedidos p ON p.cliente_id = c.id
WHERE p.id IS NULL;
-- Marta
```

### RIGHT JOIN — todas las de la derecha

```sql
SELECT c.nombre, p.importe
FROM clientes c
RIGHT JOIN pedidos p ON p.cliente_id = c.id;
-- Ana 50, Ana 30, Luis 80, NULL 20
```

(En la práctica casi siempre se usa LEFT JOIN cambiando el orden de las tablas.)

### FULL OUTER JOIN — todas las de ambos lados

```sql
SELECT c.nombre, p.importe
FROM clientes c
FULL OUTER JOIN pedidos p ON p.cliente_id = c.id;
-- Ana 50, Ana 30, Luis 80, Marta NULL, NULL 20
```

(MySQL no lo soporta; se simula con `LEFT JOIN ... UNION ... RIGHT JOIN`.)

### CROSS JOIN — producto cartesiano (todas con todas)

No lleva `ON`: combina **cada** fila de la izquierda con **cada** fila de la derecha. Si una tabla tiene 3 filas y la otra 3, salen 3 × 3 = 9.

```
tallas
+-------+
| talla |
+-------+
| S     |
| M     |
| L     |
+-------+
```

```sql
SELECT c.nombre, t.talla
FROM clientes c
CROSS JOIN tallas t;
```

```
+--------+-------+
| nombre | talla |
+--------+-------+
| Ana    | S     |
| Ana    | M     |
| Ana    | L     |
| Luis   | S     |
| Luis   | M     |
| Luis   | L     |
| Marta  | S     |
| Marta  | M     |
| Marta  | L     |
+--------+-------+
```

Sirve para generar todas las combinaciones posibles (productos × tallas, empleados × días del mes...). Ojo con tablas grandes: 10.000 × 10.000 = 100 millones de filas.

Curiosidad: un `INNER JOIN` es en realidad un `CROSS JOIN` al que luego se le aplica el filtro del `ON`. Y escribir `FROM clientes, tallas` (con coma y sin `WHERE`) también da un producto cartesiano, muchas veces sin querer.

### SELF JOIN — una tabla consigo misma

```
empleados
+----+--------+---------+
| id | nombre | jefe_id |
+----+--------+---------+
| 1  | Carmen | NULL    |   <- la jefa, no tiene jefe
| 2  | Pedro  | 1       |
| 3  | Lucía  | 1       |
| 4  | Jorge  | 2       |
+----+--------+---------+
```

```sql
SELECT e.nombre AS empleado, j.nombre AS jefe
FROM empleados e
LEFT JOIN empleados j ON e.jefe_id = j.id;
```

```
+----------+--------+
| empleado | jefe   |
+----------+--------+
| Carmen   | NULL   |
| Pedro    | Carmen |
| Lucía    | Carmen |
| Jorge    | Pedro  |
+----------+--------+
```

La misma tabla aparece dos veces con alias distintos (`e` = el empleado, `j` = su jefe). Con `INNER JOIN` en vez de `LEFT JOIN`, Carmen desaparecería, porque su `jefe_id` es NULL y no encuentra pareja.

### JOIN + GROUP BY (combinación muy común)

```sql
SELECT c.nombre, COUNT(p.id) AS num_pedidos, COALESCE(SUM(p.importe), 0) AS total
FROM clientes c
LEFT JOIN pedidos p ON p.cliente_id = c.id
GROUP BY c.id, c.nombre
ORDER BY total DESC, c.nombre;
```

```
+--------+-------------+-------+
| nombre | num_pedidos | total |
+--------+-------------+-------+
| Ana    | 2           | 80    |
| Luis   | 1           | 80    |
| Marta  | 0           | 0     |
+--------+-------------+-------+
```

Fíjate en `COUNT(p.id)` y no `COUNT(*)`: Marta tiene una fila en el LEFT JOIN (con `p.id` a NULL), así que `COUNT(*)` daría 1, mientras que `COUNT(p.id)` da 0, que es lo correcto. Y `SUM` de solo NULL da NULL; de ahí el `COALESCE(..., 0)`.

---

## 8. Subconsultas (subselects) · 🟡 ⭐⭐⭐

Un `SELECT` dentro de otro.

### En el WHERE con un valor único

```sql
-- Pedidos por encima de la media
SELECT * FROM pedidos
WHERE importe > (SELECT AVG(importe) FROM pedidos);
```

### En el WHERE con IN / NOT IN

```sql
-- Clientes que han hecho algún pedido
SELECT nombre FROM clientes
WHERE id IN (SELECT cliente_id FROM pedidos);

-- Clientes que nunca han pedido
SELECT nombre FROM clientes
WHERE id NOT IN (SELECT cliente_id FROM pedidos WHERE cliente_id IS NOT NULL);
```

> ⚠️ `NOT IN` con algún `NULL` en la subconsulta devuelve **nada**. Por eso el filtro `IS NOT NULL`, o mejor usar `NOT EXISTS`.

### EXISTS / NOT EXISTS (subconsulta correlacionada)

```sql
-- Clientes con al menos un pedido de más de 100
SELECT c.nombre FROM clientes c
WHERE EXISTS (
    SELECT 1 FROM pedidos p
    WHERE p.cliente_id = c.id AND p.importe > 100
);
```

"Correlacionada" = la subconsulta usa columnas de la consulta de fuera (`c.id`), así que se evalúa por cada fila.

### En el SELECT (subconsulta escalar)

```sql
SELECT c.nombre,
       (SELECT COUNT(*) FROM pedidos p WHERE p.cliente_id = c.id) AS num_pedidos
FROM clientes c;
```

### En el FROM (tabla derivada)

```sql
-- Media del gasto total por cliente
SELECT AVG(total) AS gasto_medio
FROM (
    SELECT cliente_id, SUM(importe) AS total
    FROM pedidos
    GROUP BY cliente_id
) AS totales;            -- el alias es obligatorio en la mayoría de motores
```

### CTE con WITH (subconsulta con nombre, más legible)

```sql
WITH totales AS (
    SELECT cliente_id, SUM(importe) AS total
    FROM pedidos
    GROUP BY cliente_id
)
SELECT c.nombre, t.total
FROM totales t
JOIN clientes c ON c.id = t.cliente_id
WHERE t.total > 100;
```

### ANY / ALL

```sql
-- Pedidos mayores que TODOS los pedidos del cliente 1
SELECT * FROM pedidos
WHERE importe > ALL (SELECT importe FROM pedidos WHERE cliente_id = 1);
```

---

## 9. UNION, INTERSECT, EXCEPT · 🟡 ⭐⭐

Combinan resultados de varios SELECT (mismo nº de columnas y tipos compatibles).

```sql
SELECT ciudad FROM clientes
UNION                -- une y quita duplicados
SELECT ciudad FROM proveedores;

SELECT ciudad FROM clientes
UNION ALL            -- une y mantiene duplicados (más rápido)
SELECT ciudad FROM proveedores;

SELECT ciudad FROM clientes
INTERSECT            -- solo las que están en ambos
SELECT ciudad FROM proveedores;

SELECT ciudad FROM clientes
EXCEPT               -- las de arriba que no están abajo (MINUS en Oracle)
SELECT ciudad FROM proveedores;
```

---

## 10. Funciones útiles · 🟢 ⭐⭐

### CASE (if/else)

```sql
SELECT producto, importe,
       CASE
           WHEN importe >= 100 THEN 'caro'
           WHEN importe >= 50  THEN 'medio'
           ELSE 'barato'
       END AS rango
FROM pedidos;
```

### Nulos

```sql
SELECT COALESCE(email, 'sin email') FROM clientes;   -- primer valor no nulo
SELECT NULLIF(importe, 0) FROM pedidos;              -- NULL si importe = 0
```

### Texto

```sql
UPPER(nombre), LOWER(nombre)
LENGTH(nombre)                -- LEN() en SQL Server
TRIM(nombre)
SUBSTRING(nombre, 1, 3)
CONCAT(nombre, ' - ', ciudad) -- o nombre || ' - ' || ciudad en PostgreSQL/SQLite
REPLACE(email, '@', ' at ')
```

### Fechas (varían bastante según el motor)

```sql
CURRENT_DATE, CURRENT_TIMESTAMP
EXTRACT(YEAR FROM fecha)      -- PostgreSQL / MySQL
YEAR(fecha)                   -- MySQL / SQL Server
```

---

## 11. Índices y vistas (lo justo) · 🟡 ⭐⭐

```sql
CREATE INDEX idx_pedidos_cliente ON pedidos(cliente_id);  -- acelera búsquedas/joins
DROP INDEX idx_pedidos_cliente;

CREATE VIEW resumen_clientes AS                            -- "consulta guardada"
SELECT c.nombre, SUM(p.importe) AS total
FROM clientes c JOIN pedidos p ON p.cliente_id = c.id
GROUP BY c.nombre;

SELECT * FROM resumen_clientes WHERE total > 100;
```

---

## 12. Transacciones · 🟡 ⭐⭐⭐

```sql
BEGIN;   -- o START TRANSACTION
UPDATE cuentas SET saldo = saldo - 100 WHERE id = 1;
UPDATE cuentas SET saldo = saldo + 100 WHERE id = 2;
COMMIT;  -- confirma los cambios

-- Si algo falla:
ROLLBACK; -- deshace todo desde el BEGIN
```

---

## 13. Procedimientos almacenados · 🟡 ⭐⭐

Un procedimiento almacenado es un bloque de SQL con nombre que se guarda **en la base de datos** y se ejecuta con una llamada. Puede recibir parámetros, usar variables, `IF`, bucles y transacciones.

Sirven para:
- Reutilizar lógica: se escribe una vez y se llama desde cualquier aplicación.
- Hacer operaciones de varios pasos en una sola llamada, con menos idas y vueltas al servidor.
- Seguridad: puedes dar permiso para ejecutar el procedimiento sin dar acceso directo a las tablas.

> ⚠️ La sintaxis cambia **mucho** según el motor. Abajo va en **MySQL**, y al final están las equivalencias en SQL Server y PostgreSQL.

### Procedimiento básico con parámetro de entrada

```sql
DELIMITER //                      -- cambia el fin de sentencia para que los ; de dentro no corten el CREATE

CREATE PROCEDURE pedidos_de_cliente(IN p_cliente_id INT)
BEGIN
    SELECT id, importe
    FROM pedidos
    WHERE cliente_id = p_cliente_id
    ORDER BY id;
END //

DELIMITER ;                       -- vuelve al ; normal
```

```sql
CALL pedidos_de_cliente(1);
```

```
+----+---------+
| id | importe |
+----+---------+
| 10 | 50      |
| 11 | 30      |
+----+---------+
```

### Parámetro de salida (OUT)

```sql
DELIMITER //

CREATE PROCEDURE total_cliente(IN p_cliente_id INT, OUT p_total DECIMAL(10,2))
BEGIN
    SELECT COALESCE(SUM(importe), 0)
    INTO p_total                  -- guarda el resultado en el parámetro de salida
    FROM pedidos
    WHERE cliente_id = p_cliente_id;
END //

DELIMITER ;
```

```sql
CALL total_cliente(1, @total);    -- @total es una variable de sesión
SELECT @total;
```

```
+--------+
| @total |
+--------+
| 80.00  |
+--------+
```

Tipos de parámetro: `IN` (entrada, el valor por defecto), `OUT` (salida) e `INOUT` (entra un valor y sale modificado).

### Variables, IF y errores

```sql
DELIMITER //

CREATE PROCEDURE aplicar_descuento(IN p_cliente_id INT, IN p_pct DECIMAL(5,2))
BEGIN
    DECLARE v_num_pedidos INT;            -- variable local (siempre al principio del BEGIN)

    IF p_pct <= 0 OR p_pct > 50 THEN
        SIGNAL SQLSTATE '45000'           -- lanza un error y corta la ejecución
            SET MESSAGE_TEXT = 'Descuento fuera de rango (0-50%)';
    END IF;

    SELECT COUNT(*) INTO v_num_pedidos
    FROM pedidos WHERE cliente_id = p_cliente_id;

    IF v_num_pedidos = 0 THEN
        SELECT 'El cliente no tiene pedidos' AS mensaje;
    ELSE
        UPDATE pedidos
        SET importe = importe * (1 - p_pct / 100)
        WHERE cliente_id = p_cliente_id;

        SELECT ROW_COUNT() AS pedidos_actualizados;
    END IF;
END //

DELIMITER ;
```

```sql
CALL aplicar_descuento(1, 10);
-- pedidos_actualizados = 2   (los de Ana pasan de 50 y 30 a 45 y 27)

CALL aplicar_descuento(3, 10);
-- mensaje = 'El cliente no tiene pedidos'   (Marta)

CALL aplicar_descuento(1, 80);
-- ERROR 1644 (45000): Descuento fuera de rango (0-50%)
```

### Con transacción (todo o nada)

Usa la tabla `cuentas` del apartado de transacciones:

```sql
DELIMITER //

CREATE PROCEDURE transferir(IN p_origen INT, IN p_destino INT, IN p_cantidad DECIMAL(10,2))
BEGIN
    -- Si ocurre cualquier error SQL: deshace todo y relanza el error
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
        UPDATE cuentas SET saldo = saldo - p_cantidad WHERE id = p_origen;
        UPDATE cuentas SET saldo = saldo + p_cantidad WHERE id = p_destino;
    COMMIT;
END //

DELIMITER ;

CALL transferir(1, 2, 100);
```

### Bucle (WHILE)

```sql
DELIMITER //

CREATE PROCEDURE rellenar_tallas()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 3 DO
        INSERT INTO tallas (talla) VALUES (ELT(i, 'S', 'M', 'L'));  -- ELT elige el i-ésimo valor
        SET i = i + 1;
    END WHILE;
END //

DELIMITER ;
```

(En SQL, casi siempre es mejor operar sobre conjuntos que usar bucles. Un solo `INSERT ... VALUES (...), (...), (...)` haría lo mismo.)

### Gestionarlos

```sql
SHOW PROCEDURE STATUS WHERE Db = DATABASE();   -- listar los de la base actual
SHOW CREATE PROCEDURE aplicar_descuento;       -- ver el código
DROP PROCEDURE IF EXISTS aplicar_descuento;    -- borrar
```

Para modificar uno en MySQL se hace `DROP` + `CREATE` de nuevo (no existe `CREATE OR REPLACE PROCEDURE`).

### Lo mismo en otros motores

**SQL Server (T-SQL):** los parámetros llevan `@`, no hace falta `DELIMITER` y se ejecuta con `EXEC`.

```sql
CREATE OR ALTER PROCEDURE total_cliente
    @cliente_id INT,
    @total DECIMAL(10,2) OUTPUT
AS
BEGIN
    SELECT @total = COALESCE(SUM(importe), 0)
    FROM pedidos
    WHERE cliente_id = @cliente_id;
END;

DECLARE @t DECIMAL(10,2);
EXEC total_cliente @cliente_id = 1, @total = @t OUTPUT;
SELECT @t;   -- 80.00
```

**PostgreSQL:** el cuerpo va entre `$$` y se indica el lenguaje (`plpgsql`). Los `PROCEDURE` se usan para hacer cambios; para **devolver datos** se usa una `FUNCTION`.

```sql
CREATE OR REPLACE PROCEDURE aplicar_descuento(p_cliente_id INT, p_pct NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_pct <= 0 OR p_pct > 50 THEN
        RAISE EXCEPTION 'Descuento fuera de rango (0-50%%)';
    END IF;

    UPDATE pedidos
    SET importe = importe * (1 - p_pct / 100)
    WHERE cliente_id = p_cliente_id;
END;
$$;

CALL aplicar_descuento(1, 10);
```

```sql
-- Función que devuelve una tabla: se usa dentro de un SELECT
CREATE OR REPLACE FUNCTION pedidos_de_cliente(p_cliente_id INT)
RETURNS TABLE (id INT, importe NUMERIC)
LANGUAGE sql
AS $$
    SELECT p.id, p.importe FROM pedidos p WHERE p.cliente_id = p_cliente_id;
$$;

SELECT * FROM pedidos_de_cliente(1);
```

### Procedimiento vs función

|                          | Procedimiento                 | Función                              |
|--------------------------|-------------------------------|--------------------------------------|
| Cómo se llama            | `CALL` / `EXEC`               | Dentro de una consulta: `SELECT f(x)` |
| Devuelve                 | Nada, parámetros OUT o resultados de SELECT | Un valor o una tabla       |
| Puede modificar datos    | Sí                            | Normalmente no, o con restricciones  |
| Puede manejar transacciones | Sí (`COMMIT` / `ROLLBACK`) | No                                   |

---

# Ampliación

---

## 14. Trampas con NULL · 🟢 ⭐⭐⭐

`NULL` no es un valor: significa **"desconocido"**. Por eso no se comporta como un 0 o un texto vacío, y es la fuente de errores más habitual en SQL.

### NULL nunca es igual a nada (ni a otro NULL)

```sql
SELECT * FROM clientes WHERE email = NULL;      -- ❌ no devuelve nada, nunca
SELECT * FROM clientes WHERE email IS NULL;     -- ✅

-- Comparar dos columnas que pueden ser NULL
WHERE a <=> b                    -- MySQL ("igual seguro con NULL")
WHERE a IS NOT DISTINCT FROM b   -- PostgreSQL / estándar
```

SQL usa lógica de **tres valores**: verdadero, falso y desconocido. `NULL = NULL` da *desconocido*, y el `WHERE` solo deja pasar lo *verdadero*.

### Los filtros "negativos" se comen los NULL

```
clientes: Ana (Madrid), Luis (Sevilla), Marta (NULL)
```

```sql
SELECT nombre FROM clientes WHERE ciudad <> 'Madrid';
-- Luis      ← ¡Marta no sale! NULL <> 'Madrid' es "desconocido"

SELECT nombre FROM clientes WHERE ciudad <> 'Madrid' OR ciudad IS NULL;
-- Luis, Marta
```

### Las funciones de agregación ignoran los NULL

```
importes: 10, NULL, 20
```

```sql
SELECT COUNT(*)        -- 3   (cuenta filas)
     , COUNT(importe)  -- 2   (cuenta valores no nulos)
     , SUM(importe)    -- 30
     , AVG(importe)    -- 15  (30 / 2, ¡no 30 / 3 = 10!)
FROM t;

SELECT AVG(COALESCE(importe, 0)) FROM t;   -- 10, si quieres que NULL cuente como 0
```

### Operar con NULL da NULL

```sql
SELECT 100 + NULL;                 -- NULL
SELECT importe * NULL;             -- NULL
SELECT CONCAT('Hola ', NULL);      -- NULL en MySQL; 'Hola ' en PostgreSQL
SELECT 'Hola ' || NULL;            -- NULL en PostgreSQL / SQLite
```

### Otros detalles

- **`NOT IN` con un NULL en la lista no devuelve nada** (ver sección 8). Usa `NOT EXISTS`.
- **`GROUP BY`** junta todos los NULL en un mismo grupo.
- **`ORDER BY`**: los NULL salen primero en MySQL y SQL Server (con ASC) y al final en PostgreSQL y Oracle. En PostgreSQL puedes forzarlo con `ORDER BY ciudad NULLS LAST`.
- **`UNIQUE`** permite varios NULL en la mayoría de motores (SQL Server solo permite uno).

---

## 15. Restricciones (constraints) a fondo · 🟢 ⭐⭐⭐

Las restricciones hacen que la **base de datos** impida datos incorrectos, en vez de confiar en que la aplicación nunca se equivoque.

```sql
CREATE TABLE pedidos (
    id          INT AUTO_INCREMENT PRIMARY KEY,            -- id automático
    cliente_id  INT NOT NULL,
    producto    VARCHAR(100) NOT NULL,
    importe     DECIMAL(10,2) NOT NULL CHECK (importe >= 0),
    estado      VARCHAR(20) DEFAULT 'pendiente'
                CHECK (estado IN ('pendiente', 'enviado', 'entregado')),
    fecha       DATE NOT NULL,

    CONSTRAINT fk_pedidos_cliente
        FOREIGN KEY (cliente_id) REFERENCES clientes(id)
        ON DELETE CASCADE           -- si se borra el cliente, se borran sus pedidos
        ON UPDATE CASCADE,          -- si cambia el id del cliente, se actualiza aquí

    CONSTRAINT uq_pedido_dia
        UNIQUE (cliente_id, producto, fecha)   -- único sobre varias columnas
);
```

| Restricción    | Qué impide                                                |
|----------------|-----------------------------------------------------------|
| `NOT NULL`     | Dejar la columna vacía                                    |
| `UNIQUE`       | Valores repetidos                                         |
| `PRIMARY KEY`  | Repetidos y NULL (= `UNIQUE` + `NOT NULL`); una por tabla |
| `FOREIGN KEY`  | Apuntar a una fila que no existe en la otra tabla         |
| `CHECK`        | Valores que no cumplen una condición                      |
| `DEFAULT`      | (No impide nada) Pone un valor si no se indica           |

### Si se viola una restricción

```sql
INSERT INTO pedidos (cliente_id, producto, importe, fecha)
VALUES (1, 'Teclado', -5, '2026-01-10');
-- ERROR: Check constraint 'pedidos_chk_1' is violated.

INSERT INTO pedidos (cliente_id, producto, importe, fecha)
VALUES (999, 'Teclado', 50, '2026-01-10');
-- ERROR: Cannot add or update a child row: a foreign key constraint fails
```

### Opciones de ON DELETE / ON UPDATE

| Opción                  | Al borrar el cliente...                                   |
|-------------------------|-----------------------------------------------------------|
| `RESTRICT` / `NO ACTION`| Da error si tiene pedidos (es lo que pasa por defecto)    |
| `CASCADE`               | Borra también sus pedidos                                 |
| `SET NULL`              | Deja `cliente_id = NULL` en sus pedidos                   |
| `SET DEFAULT`           | Pone el valor por defecto (poco soportado)                |

> ⚠️ `CASCADE` es cómodo pero peligroso: un `DELETE` puede borrar mucho más de lo que parece.

### IDs automáticos según el motor

```sql
id INT AUTO_INCREMENT PRIMARY KEY                    -- MySQL
id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY      -- PostgreSQL (moderno); antes: id SERIAL
id INT IDENTITY(1,1) PRIMARY KEY                     -- SQL Server
id INTEGER PRIMARY KEY AUTOINCREMENT                 -- SQLite
```

### Clave primaria compuesta

```sql
-- Una línea por cada producto de cada pedido
CREATE TABLE lineas_pedido (
    pedido_id   INT,
    producto_id INT,
    cantidad    INT NOT NULL CHECK (cantidad > 0),
    PRIMARY KEY (pedido_id, producto_id)       -- la pareja no se puede repetir
);
```

### Añadir o quitar restricciones a una tabla existente

```sql
ALTER TABLE clientes ADD CONSTRAINT uq_email UNIQUE (email);
ALTER TABLE clientes ADD CONSTRAINT chk_nombre CHECK (LENGTH(nombre) > 1);
ALTER TABLE clientes DROP CONSTRAINT chk_nombre;    -- MySQL < 8.0.19: DROP CHECK / DROP INDEX
```

(En MySQL, `CHECK` solo se aplica de verdad desde la versión 8.0.16; antes se ignoraba sin avisar.)

---

## 16. Normalización · 🟢 ⭐⭐

Es la forma de repartir los datos en tablas para **no repetir información**. Repetir datos provoca incoherencias: si la ciudad de Ana aparece en 50 filas, tarde o temprano alguna no se actualizará.

### Tabla mal diseñada

```
pedidos_mal
+-----------+---------+---------+------------------+---------+
| pedido_id | cliente | ciudad  | productos        | importe |
+-----------+---------+---------+------------------+---------+
| 10        | Ana     | Madrid  | Teclado, Ratón   | 80      |
| 11        | Ana     | Madrid  | Monitor          | 120     |
| 12        | Luis    | Sevilla | Monitor, Teclado | 130     |
+-----------+---------+---------+------------------+---------+
```

### 1ª forma normal (1FN): un valor por celda

Nada de listas como `"Teclado, Ratón"`, ni columnas repetidas tipo `producto1, producto2, producto3`. Cada producto va en su propia fila, en una tabla `lineas_pedido`.

> Si te ves haciendo `LIKE '%Teclado%'` para buscar dentro de una lista, la tabla no está en 1FN.

### 2ª forma normal (2FN): todo depende de la clave **completa**

Solo afecta a las tablas con clave compuesta. En `lineas_pedido(pedido_id, producto_id, cantidad, nombre_producto)`, `nombre_producto` depende solo de `producto_id`, no de la pareja entera. Por tanto se lleva a su propia tabla `productos(id, nombre, precio)`.

### 3ª forma normal (3FN): nada depende de otra columna que no sea la clave

En `pedidos(id, cliente_id, ciudad_cliente)`, la ciudad depende del **cliente**, no del pedido. Va en `clientes`.

### Resultado

```
clientes(id, nombre, ciudad)
productos(id, nombre, precio)
pedidos(id, cliente_id, fecha)
lineas_pedido(pedido_id, producto_id, cantidad)
```

Resumen clásico: *cada columna depende de la clave, de toda la clave y de nada más que la clave.*

> A veces se **desnormaliza** a propósito (por ejemplo, guardar un `total` ya calculado en `pedidos`) para que las consultas vayan más rápidas. Es una decisión consciente, no un descuido.

---

## 17. Funciones de ventana · 🟡 ⭐⭐⭐

Hacen cálculos sobre un grupo de filas **sin juntarlas en una sola**, a diferencia de `GROUP BY`. Cada fila conserva sus datos y además recibe el cálculo. Están disponibles en MySQL 8+, PostgreSQL, SQL Server y SQLite 3.25+.

```sql
funcion() OVER (
    PARTITION BY columna   -- grupos (opcional; sin esto, toda la tabla es un grupo)
    ORDER BY columna       -- orden dentro de cada grupo (opcional según la función)
)
```

Datos para este apartado:

```
pedidos
+----+------------+------------+---------+
| id | cliente_id | fecha      | importe |
+----+------------+------------+---------+
| 10 | 1          | 2026-01-10 | 50      |
| 11 | 1          | 2026-02-15 | 30      |
| 12 | 2          | 2026-01-20 | 80      |
| 14 | 2          | 2026-03-05 | 40      |
| 15 | 3          | 2026-02-01 | 60      |
+----+------------+------------+---------+
```

### GROUP BY vs ventana

```sql
-- GROUP BY: una fila por cliente
SELECT cliente_id, SUM(importe) AS total
FROM pedidos GROUP BY cliente_id;
```

```sql
-- Ventana: todas las filas, cada una con el total de su cliente
SELECT id, cliente_id, importe,
       SUM(importe) OVER (PARTITION BY cliente_id) AS total_cliente
FROM pedidos;
```

```
+----+------------+---------+---------------+
| id | cliente_id | importe | total_cliente |
+----+------------+---------+---------------+
| 10 | 1          | 50      | 80            |
| 11 | 1          | 30      | 80            |
| 12 | 2          | 80      | 120           |
| 14 | 2          | 40      | 120           |
| 15 | 3          | 60      | 60            |
+----+------------+---------+---------------+
```

Esto permite, por ejemplo, calcular qué porcentaje del gasto de su cliente supone cada pedido: `importe * 100.0 / SUM(importe) OVER (PARTITION BY cliente_id)`.

### ROW_NUMBER, RANK y DENSE_RANK (numerar y clasificar)

```
puntuaciones: 100, 90, 90, 80
```

```sql
SELECT puntos,
       ROW_NUMBER() OVER (ORDER BY puntos DESC) AS row_num,
       RANK()       OVER (ORDER BY puntos DESC) AS rnk,
       DENSE_RANK() OVER (ORDER BY puntos DESC) AS dense_rnk
FROM puntuaciones;
```

```
+--------+------------+------+------------+
| puntos | row_num    | rnk  | dense_rnk  |
+--------+------------+------+------------+
| 100    | 1          | 1    | 1          |
| 90     | 2          | 2    | 2          |
| 90     | 3          | 2    | 2          |
| 80     | 4          | 4    | 3          |
+--------+------------+------+------------+
```

- `ROW_NUMBER`: numera 1, 2, 3... aunque haya empates.
- `RANK`: los empates comparten puesto **y se salta** el siguiente (como en una carrera).
- `DENSE_RANK`: los empates comparten puesto, **sin saltos**.

### Top N por grupo (el uso más típico)

El pedido más caro de cada cliente:

```sql
WITH ordenados AS (
    SELECT p.*,
           ROW_NUMBER() OVER (PARTITION BY cliente_id ORDER BY importe DESC) AS rn
    FROM pedidos p
)
SELECT id, cliente_id, importe
FROM ordenados
WHERE rn = 1;            -- rn <= 3 para el top 3
```

```
+----+------------+---------+
| id | cliente_id | importe |
+----+------------+---------+
| 10 | 1          | 50      |
| 12 | 2          | 80      |
| 15 | 3          | 60      |
+----+------------+---------+
```

(No se puede poner `WHERE rn = 1` en la misma consulta, porque las ventanas se calculan después del `WHERE`. Por eso hace falta la CTE o una subconsulta.)

### Total acumulado

```sql
SELECT id, fecha, importe,
       SUM(importe) OVER (ORDER BY fecha) AS acumulado
FROM pedidos;
```

```
+----+------------+---------+-----------+
| id | fecha      | importe | acumulado |
+----+------------+---------+-----------+
| 10 | 2026-01-10 | 50      | 50        |
| 12 | 2026-01-20 | 80      | 130       |
| 15 | 2026-02-01 | 60      | 190       |
| 11 | 2026-02-15 | 30      | 220       |
| 14 | 2026-03-05 | 40      | 260       |
+----+------------+---------+-----------+
```

Con `ORDER BY` dentro del `OVER`, `SUM` suma "desde el principio hasta esta fila".

### LAG y LEAD (mirar la fila anterior o la siguiente)

```sql
SELECT id, cliente_id, fecha, importe,
       LAG(importe) OVER (PARTITION BY cliente_id ORDER BY fecha) AS anterior,
       importe - LAG(importe) OVER (PARTITION BY cliente_id ORDER BY fecha) AS diferencia
FROM pedidos;
```

```
+----+------------+------------+---------+----------+------------+
| id | cliente_id | fecha      | importe | anterior | diferencia |
+----+------------+------------+---------+----------+------------+
| 10 | 1          | 2026-01-10 | 50      | NULL     | NULL       |
| 11 | 1          | 2026-02-15 | 30      | 50       | -20        |
| 12 | 2          | 2026-01-20 | 80      | NULL     | NULL       |
| 14 | 2          | 2026-03-05 | 40      | 80       | -40        |
| 15 | 3          | 2026-02-01 | 60      | NULL     | NULL       |
+----+------------+------------+---------+----------+------------+
```

`LEAD` funciona igual, pero mira la fila **siguiente**. Las dos aceptan un valor por defecto: `LAG(importe, 1, 0)` devuelve 0 en lugar de NULL.

### Marco de la ventana (media móvil)

```sql
-- Media de este pedido y los 2 anteriores
AVG(importe) OVER (ORDER BY fecha ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
```

### Otras funciones de ventana

`FIRST_VALUE(col)`, `LAST_VALUE(col)`, `NTILE(4)` (reparte en 4 grupos, cuartiles) y cualquier agregación (`COUNT`, `AVG`, `MIN`, `MAX`) con `OVER`.

---

## 18. UPSERT (insertar o actualizar) · 🟡 ⭐⭐

"Si la fila no existe, insértala; si ya existe, actualízala", en una sola sentencia. Necesita una `PRIMARY KEY` o un `UNIQUE` para saber qué significa "ya existe".

```
inventario (producto es PRIMARY KEY)
+----------+----------+
| producto | cantidad |
+----------+----------+
| Teclado  | 10       |
+----------+----------+
```

**MySQL**

```sql
INSERT INTO inventario (producto, cantidad)
VALUES ('Teclado', 5), ('Ratón', 3) AS nuevo
ON DUPLICATE KEY UPDATE cantidad = inventario.cantidad + nuevo.cantidad;
```

(En versiones anteriores a la 8.0.19 se escribía `cantidad = cantidad + VALUES(cantidad)`.)

**PostgreSQL / SQLite**

```sql
INSERT INTO inventario (producto, cantidad)
VALUES ('Teclado', 5), ('Ratón', 3)
ON CONFLICT (producto)
DO UPDATE SET cantidad = inventario.cantidad + EXCLUDED.cantidad;   -- EXCLUDED = la fila que intentabas meter

-- Si ya existe, ignorarla:
INSERT INTO inventario VALUES ('Teclado', 5) ON CONFLICT DO NOTHING;
```

**SQL Server (MERGE)**

```sql
MERGE inventario AS t
USING (VALUES ('Teclado', 5), ('Ratón', 3)) AS s (producto, cantidad)
ON t.producto = s.producto
WHEN MATCHED THEN
    UPDATE SET t.cantidad = t.cantidad + s.cantidad
WHEN NOT MATCHED THEN
    INSERT (producto, cantidad) VALUES (s.producto, s.cantidad);
```

Resultado en todos los casos:

```
+----------+----------+
| producto | cantidad |
+----------+----------+
| Teclado  | 15       |   ← ya existía: 10 + 5
| Ratón    | 3        |   ← no existía: se inserta
+----------+----------+
```

---

## 19. Triggers · 🟡 ⭐⭐

Un trigger es un bloque de código que la base de datos ejecuta **automáticamente** cuando ocurre un `INSERT`, `UPDATE` o `DELETE` en una tabla. Es como un procedimiento almacenado que nadie llama a mano.

| Momento  | Evento                       | Puedes usar                                   |
|----------|------------------------------|-----------------------------------------------|
| `BEFORE` | `INSERT`/`UPDATE`/`DELETE` | Validar o modificar `NEW` antes de guardarlo  |
| `AFTER`  | `INSERT`/`UPDATE`/`DELETE` | Reaccionar: históricos, auditoría, totales    |

- `NEW` = la fila tal y como va a quedar (en `INSERT` y `UPDATE`).
- `OLD` = la fila como estaba antes (en `UPDATE` y `DELETE`).

### Guardar un histórico de cambios (MySQL)

```sql
CREATE TABLE historial_importes (
    id                INT AUTO_INCREMENT PRIMARY KEY,
    pedido_id         INT,
    importe_anterior  DECIMAL(10,2),
    importe_nuevo     DECIMAL(10,2),
    fecha_cambio      DATETIME
);

DELIMITER //

CREATE TRIGGER trg_pedidos_historial
AFTER UPDATE ON pedidos
FOR EACH ROW
BEGIN
    IF NOT (OLD.importe <=> NEW.importe) THEN     -- <=> para que funcione con NULL (sección 14)
        INSERT INTO historial_importes (pedido_id, importe_anterior, importe_nuevo, fecha_cambio)
        VALUES (OLD.id, OLD.importe, NEW.importe, NOW());
    END IF;
END //

DELIMITER ;
```

```sql
UPDATE pedidos SET importe = 45 WHERE id = 10;
SELECT pedido_id, importe_anterior, importe_nuevo FROM historial_importes;
```

```
+-----------+------------------+---------------+
| pedido_id | importe_anterior | importe_nuevo |
+-----------+------------------+---------------+
| 10        | 50.00            | 45.00         |
+-----------+------------------+---------------+
```

### Normalizar datos antes de guardar (BEFORE)

```sql
DELIMITER //

CREATE TRIGGER trg_clientes_email
BEFORE INSERT ON clientes
FOR EACH ROW
BEGIN
    SET NEW.email = LOWER(TRIM(NEW.email));     -- 'Ana@Mail.com ' se guarda como 'ana@mail.com'
END //

DELIMITER ;
```

### Gestionarlos

```sql
SHOW TRIGGERS;
DROP TRIGGER IF EXISTS trg_clientes_email;
```

En **PostgreSQL** se crea primero una función `RETURNS trigger` y luego `CREATE TRIGGER ... EXECUTE FUNCTION nombre()`. En **SQL Server** no existen `NEW` ni `OLD`; se usan las tablas virtuales `inserted` y `deleted`.

> ⚠️ Úsalos con moderación: es lógica "escondida", porque quien hace un `UPDATE` no ve que se dispara algo, y ralentizan cada escritura. Son ideales para auditoría e históricos. Para reglas de negocio complejas suele ser mejor la aplicación o un procedimiento.

---

## 20. Usuarios y permisos · 🟡 ⭐

Regla de oro: **mínimo privilegio**. Cada usuario o aplicación tiene solo los permisos que necesita.

**MySQL**

```sql
CREATE USER 'analista'@'localhost' IDENTIFIED BY 'cambia_esta_clave';

GRANT SELECT ON tienda.* TO 'analista'@'localhost';                    -- leer toda la BD
GRANT SELECT, INSERT, UPDATE ON tienda.pedidos TO 'app'@'%';           -- tabla concreta
GRANT EXECUTE ON PROCEDURE tienda.aplicar_descuento TO 'app'@'%';      -- solo ejecutar un procedimiento

REVOKE UPDATE ON tienda.pedidos FROM 'app'@'%';                        -- quitar un permiso

SHOW GRANTS FOR 'analista'@'localhost';
DROP USER 'analista'@'localhost';
```

### Roles (grupos de permisos)

```sql
CREATE ROLE solo_lectura;
GRANT SELECT ON tienda.* TO solo_lectura;

GRANT solo_lectura TO 'analista'@'localhost';
SET DEFAULT ROLE solo_lectura TO 'analista'@'localhost';   -- MySQL: activarlo al conectar
```

**PostgreSQL**

```sql
CREATE ROLE analista LOGIN PASSWORD 'cambia_esta_clave';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO analista;
REVOKE SELECT ON pedidos FROM analista;
```

Permisos habituales: `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `EXECUTE`, `CREATE`, `ALTER`, `DROP` y `ALL PRIVILEGES`.

---

## 21. CTE recursivas · 🔴 ⭐⭐

Una CTE que se llama a sí misma. Sirve para recorrer **jerarquías** (organigramas, categorías y subcategorías, carpetas) y para **generar series**.

Estructura:

```sql
WITH RECURSIVE nombre AS (
    -- 1) caso base: punto de partida
    SELECT ...
    UNION ALL
    -- 2) paso recursivo: se une a "nombre" para avanzar un nivel
    SELECT ... FROM tabla JOIN nombre ON ...
)
SELECT * FROM nombre;
```

### Organigrama completo

Usa la tabla `empleados` del self join (sección 7): Carmen es la jefa, Pedro y Lucía dependen de Carmen, y Jorge depende de Pedro.

```sql
WITH RECURSIVE jerarquia AS (
    SELECT id, nombre, 1 AS nivel,
           CAST(nombre AS CHAR(200)) AS ruta          -- caso base: quien no tiene jefe
    FROM empleados
    WHERE jefe_id IS NULL

    UNION ALL

    SELECT e.id, e.nombre, j.nivel + 1,
           CONCAT(j.ruta, ' > ', e.nombre)            -- paso: los subordinados de los ya encontrados
    FROM empleados e
    JOIN jerarquia j ON e.jefe_id = j.id
)
SELECT nombre, nivel, ruta
FROM jerarquia
ORDER BY ruta;
```

```
+--------+-------+-------------------------+
| nombre | nivel | ruta                    |
+--------+-------+-------------------------+
| Carmen | 1     | Carmen                  |
| Lucía  | 2     | Carmen > Lucía          |
| Pedro  | 2     | Carmen > Pedro          |
| Jorge  | 3     | Carmen > Pedro > Jorge  |
+--------+-------+-------------------------+
```

Con un self join normal solo llegas a un nivel. Con la recursiva llegas a todos, sin saber cuántos hay.

### Generar una serie (por ejemplo, días de un mes)

```sql
WITH RECURSIVE dias AS (
    SELECT DATE '2026-01-01' AS dia
    UNION ALL
    SELECT dia + INTERVAL 1 DAY FROM dias WHERE dia < '2026-01-31'
)
SELECT d.dia, COALESCE(SUM(p.importe), 0) AS ventas
FROM dias d
LEFT JOIN pedidos p ON p.fecha = d.dia
GROUP BY d.dia;           -- salen también los días SIN ventas, con 0
```

> ⚠️ Si el paso recursivo nunca deja de producir filas, el bucle es infinito. MySQL lo corta a las 1000 iteraciones (`cte_max_recursion_depth`) y SQL Server a las 100 (`OPTION (MAXRECURSION n)`).
>
> En SQL Server se escribe `WITH` sin la palabra `RECURSIVE`.

---

## 22. Índices a fondo y EXPLAIN · 🔴 ⭐⭐

Un índice es como el índice de un libro: en vez de leer todas las páginas (*full scan*), salta directamente a donde está el dato. Casi siempre se implementa como un árbol B (B-tree).

- **Ventaja:** lecturas mucho más rápidas en `WHERE`, `JOIN` y `ORDER BY`.
- **Coste:** ocupa espacio, y cada `INSERT`, `UPDATE` o `DELETE` tiene que actualizar también el índice.

### Qué indexar

- Columnas que se usan mucho en `WHERE` y en `JOIN`, sobre todo las **claves foráneas** (`pedidos.cliente_id`). La `PRIMARY KEY` ya tiene índice automáticamente.
- Columnas con muchos valores distintos (*alta selectividad*): `email` sí, `sexo` o `activo (sí/no)` normalmente no.

### Cuándo NO se usa el índice aunque exista

```sql
-- Índice en nombre
WHERE nombre LIKE 'Ana%'       -- ✅ lo usa (sabe por dónde empezar)
WHERE nombre LIKE '%Ana'       -- ❌ no puede: el comodín al principio obliga a mirarlo todo

-- Índice en fecha
WHERE YEAR(fecha) = 2026                               -- ❌ una función sobre la columna anula el índice
WHERE fecha >= '2026-01-01' AND fecha < '2027-01-01'   -- ✅ misma consulta, reescrita

-- Índice en telefono (VARCHAR)
WHERE telefono = 600123123     -- ❌ conversión de tipo implícita
WHERE telefono = '600123123'   -- ✅
```

### Índices compuestos: la regla del prefijo izquierdo

```sql
CREATE INDEX idx_cliente_fecha ON pedidos (cliente_id, fecha);
```

| Consulta                                        | ¿Usa el índice?            |
|-------------------------------------------------|----------------------------|
| `WHERE cliente_id = 1`                          | ✅                         |
| `WHERE cliente_id = 1 AND fecha > '2026-01-01'` | ✅ (ideal)                 |
| `WHERE fecha > '2026-01-01'`                    | ❌ falta la primera columna |

Funciona como una guía telefónica ordenada por (apellido, nombre): puedes buscar por apellido, pero no solo por nombre.

### EXPLAIN: ver cómo va a ejecutar la consulta

```sql
EXPLAIN SELECT * FROM pedidos WHERE cliente_id = 1;
```

Salida de ejemplo en MySQL (simplificada), **antes** de crear el índice:

```
+---------+------+------+--------+
| table   | type | key  | rows   |
+---------+------+------+--------+
| pedidos | ALL  | NULL | 100000 |   ← ALL = recorre la tabla entera
+---------+------+------+--------+
```

**Después** de `CREATE INDEX idx_pedidos_cliente ON pedidos(cliente_id)`:

```
+---------+------+---------------------+------+
| table   | type | key                 | rows |
+---------+------+---------------------+------+
| pedidos | ref  | idx_pedidos_cliente | 12   |   ← usa el índice y lee 12 filas
+---------+------+---------------------+------+
```

Qué mirar:
- **`type`**: de peor a mejor, `ALL` (toda la tabla) → `index` → `range` → `ref` → `eq_ref` → `const`.
- **`key`**: el índice que usa (`NULL` = ninguno).
- **`rows`**: cuántas filas estima que va a leer.

En **PostgreSQL**, `EXPLAIN ANALYZE` ejecuta la consulta de verdad y muestra los tiempos reales. Busca `Seq Scan` (recorrido completo) frente a `Index Scan`.

---

## 23. Aislamiento de transacciones y ACID · 🔴 ⭐

### ACID: lo que garantiza una transacción

| Letra | Propiedad    | Significa                                                              |
|-------|--------------|------------------------------------------------------------------------|
| **A** | Atomicidad   | Todo o nada: si un paso falla, se deshace todo                         |
| **C** | Consistencia | Al terminar se siguen cumpliendo todas las restricciones               |
| **I** | Aislamiento  | Las transacciones a la vez no se pisan (o se pisan lo que tú permitas) |
| **D** | Durabilidad  | Tras el `COMMIT`, el dato sobrevive aunque se caiga el servidor        |

### Problemas cuando varias transacciones van a la vez

**Lectura sucia (dirty read):** lees un cambio que otro **aún no ha confirmado** y que quizá deshaga.

**Lectura no repetible:** lees la misma fila dos veces dentro de tu transacción y obtienes valores distintos, porque otro la cambió y confirmó en medio.

| Paso | Sesión A                                     | Sesión B                                       |
|------|----------------------------------------------|------------------------------------------------|
| 1    | `BEGIN;`                                     |                                                |
| 2    | `SELECT saldo FROM cuentas WHERE id=1;` → 500 |                                                |
| 3    |                                              | `UPDATE cuentas SET saldo=300 WHERE id=1; COMMIT;` |
| 4    | `SELECT saldo FROM cuentas WHERE id=1;` → **?** |                                             |

En el paso 4: con `READ COMMITTED` → **300**; con `REPEATABLE READ` → **500**.

**Lectura fantasma (phantom read):** repites una consulta con `WHERE` y aparecen filas **nuevas** que otro ha insertado.

### Niveles de aislamiento

| Nivel              | Lectura sucia | No repetible | Fantasma |
|--------------------|:-------------:|:------------:|:--------:|
| `READ UNCOMMITTED` | ❌ puede pasar | ❌           | ❌       |
| `READ COMMITTED`   | ✅ evitado    | ❌           | ❌       |
| `REPEATABLE READ`  | ✅            | ✅           | ❌*      |
| `SERIALIZABLE`     | ✅            | ✅           | ✅       |

\* MySQL (InnoDB) también evita la mayoría de fantasmas en `REPEATABLE READ`.

Más aislamiento significa más seguridad, pero más bloqueos y menos rendimiento.

- Por defecto: **MySQL** usa `REPEATABLE READ`; **PostgreSQL**, **SQL Server** y **Oracle** usan `READ COMMITTED`.

```sql
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;   -- para la siguiente transacción
BEGIN;
...
COMMIT;
```

### Actualización perdida y SELECT ... FOR UPDATE

Dos sesiones leen `stock = 10`, las dos venden 1 y las dos guardan `stock = 9`. Deberían quedar 8. Para evitarlo, se **bloquea la fila** al leerla:

```sql
BEGIN;
SELECT cantidad FROM inventario WHERE producto = 'Teclado' FOR UPDATE;  -- otros esperan aquí
UPDATE inventario SET cantidad = cantidad - 1 WHERE producto = 'Teclado';
COMMIT;                                                                 -- se libera el bloqueo
```

(Para este caso concreto, un único `UPDATE ... SET cantidad = cantidad - 1` ya es seguro por sí solo. `FOR UPDATE` hace falta cuando lees, decides algo en la aplicación y luego escribes.)

### Deadlock (interbloqueo)

A bloquea la fila 1 y espera a la 2, mientras B bloquea la 2 y espera a la 1. El motor lo detecta y **cancela una de las dos** con un error. La aplicación debe reintentarla.

Para evitarlo: transacciones cortas y acceder a las filas siempre en el mismo orden.

---

## 24. Ejercicios con solución · 🟢🟡🔴

Script para crear los datos (bórralo todo antes si ya tenías estas tablas):

```sql
DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS clientes;

CREATE TABLE clientes (
    id INT PRIMARY KEY, nombre VARCHAR(100), email VARCHAR(150),
    ciudad VARCHAR(50), fecha_alta DATE
);
CREATE TABLE pedidos (
    id INT PRIMARY KEY, cliente_id INT REFERENCES clientes(id),
    producto VARCHAR(100), importe DECIMAL(10,2), fecha DATE
);

INSERT INTO clientes VALUES
    (1, 'Ana',   'ana@mail.com',    'Madrid',   '2025-03-01'),
    (2, 'Luis',  NULL,              'Sevilla',  '2025-06-15'),
    (3, 'Marta', 'marta@gmail.com', 'Madrid',   '2026-01-10'),
    (4, 'Pablo', 'pablo@gmail.com', 'Valencia', '2026-02-20');

INSERT INTO pedidos VALUES
    (10, 1, 'Teclado',  50, '2026-01-10'),
    (11, 1, 'Ratón',    30, '2026-02-15'),
    (12, 2, 'Monitor',  80, '2026-01-20'),
    (14, 2, 'Teclado',  40, '2026-03-05'),
    (15, 3, 'Monitor',  60, '2026-02-01'),
    (16, 1, 'Monitor', 120, '2026-03-12');
```

Intenta cada uno antes de abrir la solución.

### 🟢 1. Clientes de Madrid, ordenados por nombre

<details><summary>Solución</summary>

```sql
SELECT nombre FROM clientes
WHERE ciudad = 'Madrid'
ORDER BY nombre;
```
Resultado: Ana, Marta
</details>

### 🟢 2. Clientes con email de Gmail

<details><summary>Solución</summary>

```sql
SELECT nombre, email FROM clientes
WHERE email LIKE '%@gmail.com';
```
Resultado: Marta, Pablo
</details>

### 🟢 3. Clientes que no tienen email

<details><summary>Solución</summary>

```sql
SELECT nombre FROM clientes WHERE email IS NULL;
```
Resultado: Luis. (`= NULL` no funcionaría; ver sección 14.)
</details>

### 🟢 4. Número de pedidos e importe total por producto

<details><summary>Solución</summary>

```sql
SELECT producto, COUNT(*) AS num_pedidos, SUM(importe) AS total
FROM pedidos
GROUP BY producto
ORDER BY total DESC;
```
Resultado: Monitor 3 / 260 · Teclado 2 / 90 · Ratón 1 / 30
</details>

### 🟡 5. Total gastado por cada cliente, incluidos los que no han pedido nada

<details><summary>Solución</summary>

```sql
SELECT c.nombre, COALESCE(SUM(p.importe), 0) AS total
FROM clientes c
LEFT JOIN pedidos p ON p.cliente_id = c.id
GROUP BY c.id, c.nombre
ORDER BY total DESC;
```
Resultado: Ana 200 · Luis 120 · Marta 60 · Pablo 0
</details>

### 🟡 6. Clientes que nunca han hecho un pedido

<details><summary>Solución</summary>

```sql
SELECT c.nombre FROM clientes c
WHERE NOT EXISTS (SELECT 1 FROM pedidos p WHERE p.cliente_id = c.id);
```
Resultado: Pablo. (También vale `LEFT JOIN ... WHERE p.id IS NULL`.)
</details>

### 🟡 7. Pedidos con importe superior a la media

<details><summary>Solución</summary>

```sql
SELECT id, producto, importe FROM pedidos
WHERE importe > (SELECT AVG(importe) FROM pedidos);
```
Media = 380 / 6 ≈ 63,33. Resultado: pedido 12 (80) y pedido 16 (120)
</details>

### 🟡 8. Ciudades con más de un cliente

<details><summary>Solución</summary>

```sql
SELECT ciudad, COUNT(*) AS num_clientes
FROM clientes
GROUP BY ciudad
HAVING COUNT(*) > 1;
```
Resultado: Madrid 2
</details>

### 🟡 9. Clientes que han gastado más que la media de gasto por cliente (contando solo los que han pedido)

<details><summary>Solución</summary>

```sql
WITH totales AS (
    SELECT cliente_id, SUM(importe) AS total
    FROM pedidos
    GROUP BY cliente_id
)
SELECT c.nombre, t.total
FROM totales t
JOIN clientes c ON c.id = t.cliente_id
WHERE t.total > (SELECT AVG(total) FROM totales);
```
Totales: 200, 120 y 60, con una media de ≈ 126,67. Resultado: Ana (200)
</details>

### 🔴 10. El pedido más caro de cada cliente

<details><summary>Solución</summary>

```sql
WITH ordenados AS (
    SELECT p.*,
           ROW_NUMBER() OVER (PARTITION BY cliente_id ORDER BY importe DESC) AS rn
    FROM pedidos p
)
SELECT c.nombre, o.producto, o.importe
FROM ordenados o
JOIN clientes c ON c.id = o.cliente_id
WHERE o.rn = 1;
```
Resultado: Ana Monitor 120 · Luis Monitor 80 · Marta Monitor 60
</details>

### 🔴 11. Gasto acumulado de cada cliente a lo largo del tiempo

<details><summary>Solución</summary>

```sql
SELECT c.nombre, p.fecha, p.importe,
       SUM(p.importe) OVER (PARTITION BY p.cliente_id ORDER BY p.fecha) AS acumulado
FROM pedidos p
JOIN clientes c ON c.id = p.cliente_id
ORDER BY c.nombre, p.fecha;
```
Resultado:
- Ana: 50 → 80 → 200
- Luis: 80 → 120
- Marta: 60
</details>

### 🔴 12. Diferencia de cada pedido con el anterior del mismo cliente

<details><summary>Solución</summary>

```sql
SELECT c.nombre, p.fecha, p.importe,
       p.importe - LAG(p.importe) OVER (PARTITION BY p.cliente_id ORDER BY p.fecha) AS diferencia
FROM pedidos p
JOIN clientes c ON c.id = p.cliente_id
ORDER BY c.nombre, p.fecha;
```
Resultado:
- Ana: NULL, −20, +90
- Luis: NULL, −40
- Marta: NULL
</details>

### 🔴 13. Ranking de clientes por gasto total (los empates comparten puesto)

<details><summary>Solución</summary>

```sql
SELECT c.nombre, SUM(p.importe) AS total,
       DENSE_RANK() OVER (ORDER BY SUM(p.importe) DESC) AS puesto
FROM clientes c
JOIN pedidos p ON p.cliente_id = c.id
GROUP BY c.id, c.nombre;
```
Resultado: Ana 1 · Luis 2 · Marta 3. La ventana se aplica sobre el resultado del `GROUP BY`, por eso puede usar `SUM(...)`.
</details>

---

## Chuleta final

| Quiero...                              | Uso                              |
|----------------------------------------|----------------------------------|
| Filtrar filas                          | `WHERE`                          |
| Buscar texto parecido                  | `LIKE '%texto%'`                 |
| Valor en una lista                     | `IN (...)`                       |
| Rango                                  | `BETWEEN a AND b`                |
| Comprobar nulos                        | `IS NULL` / `IS NOT NULL`        |
| Quitar duplicados                      | `DISTINCT`                       |
| Agrupar y resumir                      | `GROUP BY` + `COUNT/SUM/AVG...`  |
| Filtrar grupos                         | `HAVING`                         |
| Datos de 2 tablas que coinciden        | `INNER JOIN`                     |
| Todos de A aunque no estén en B        | `LEFT JOIN`                      |
| Los de A que NO están en B             | `LEFT JOIN ... WHERE b.id IS NULL` o `NOT EXISTS` |
| Comparar con un cálculo de la tabla    | Subconsulta en el `WHERE`        |
| Consulta compleja legible              | `WITH` (CTE)                     |
| Juntar resultados de dos consultas     | `UNION` / `UNION ALL`            |
| Condicionales                          | `CASE WHEN ... THEN ... END`     |
| Guardar lógica reutilizable en la BD   | `CREATE PROCEDURE` + `CALL`      |
| Comparar con NULL                      | `IS NULL`, nunca `= NULL`        |
| Impedir datos incorrectos              | `NOT NULL`, `UNIQUE`, `CHECK`, `FOREIGN KEY` |
| Cálculo por grupo sin perder filas     | `SUM(...) OVER (PARTITION BY ...)` |
| Top N por grupo                        | `ROW_NUMBER() OVER (...)` + filtrar `rn <= N` |
| Total acumulado                        | `SUM(...) OVER (ORDER BY ...)`   |
| Comparar con la fila anterior          | `LAG(...) OVER (...)`            |
| Insertar o actualizar si existe        | `ON DUPLICATE KEY` / `ON CONFLICT` / `MERGE` |
| Reaccionar automáticamente a cambios   | `CREATE TRIGGER`                 |
| Dar o quitar permisos                  | `GRANT` / `REVOKE`               |
| Recorrer jerarquías o generar series   | `WITH RECURSIVE`                 |
| Ver si una consulta usa índices        | `EXPLAIN`                        |
| Bloquear una fila para modificarla     | `SELECT ... FOR UPDATE`          |
