CREATE TABLE customer (
    customer_id INTEGER,
    first_name VARCHAR,
    last_name VARCHAR,
    gender VARCHAR,
    date_of_birth VARCHAR,
    job_title VARCHAR,
    job_industry_category VARCHAR,
    wealth_segment VARCHAR,
    deceased_indicator VARCHAR,
    owns_car VARCHAR,
    address TEXT,
    postcode VARCHAR,
    state VARCHAR,
    country VARCHAR,
    property_valuation VARCHAR
);

CREATE TABLE product (
    product_id INTEGER,
    brand VARCHAR,
    product_line VARCHAR,
    product_class VARCHAR,
    product_size VARCHAR,
    list_price NUMERIC,
    standard_cost NUMERIC
);

CREATE TABLE orders (
    order_id INTEGER,
    customer_id INTEGER,
    order_date VARCHAR,
    online_order VARCHAR,
    order_status VARCHAR
);

CREATE TABLE order_items (
    order_item_id INTEGER,
    order_id INTEGER,
    product_id INTEGER,
    quantity INTEGER,
    item_list_price_at_sale NUMERIC,
    item_standard_cost_at_sale NUMERIC
);

-- Вывести все таблицы в текущей базе данных
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE';

-- Проверка количества записей во всех таблицах
SELECT 
    'customer' as table_name,
    COUNT(*) as record_count
FROM customer

UNION ALL

SELECT 
    'product',
    COUNT(*) 
FROM product

UNION ALL

SELECT 
    'orders',
    COUNT(*) 
FROM orders

UNION ALL

SELECT 
    'order_items',
    COUNT(*) 
FROM order_items

ORDER BY table_name;

-- Посмотрим уникальные значения и их количество
SELECT 
    online_order,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2) as percentage
FROM orders 
GROUP BY online_order 
ORDER BY count DESC;

-- Посмотрим примеры записей
SELECT order_id, online_order 
FROM orders 
LIMIT 10;

-- Анализ полей в таблице customer:
-- Анализ date_of_birth
SELECT 
    date_of_birth,
    COUNT(*) as count
FROM customer 
GROUP BY date_of_birth 
ORDER BY count DESC 
LIMIT 10;

-- Анализ deceased_indicator
SELECT 
    deceased_indicator,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer), 2) as percentage
FROM customer 
GROUP BY deceased_indicator 
ORDER BY count DESC;

-- Анализ owns_car
SELECT 
    owns_car,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer), 2) as percentage
FROM customer 
GROUP BY owns_car 
ORDER BY count DESC;

-- Анализ property_valuation
SELECT 
    property_valuation,
    COUNT(*) as count
FROM customer 
GROUP BY property_valuation 
ORDER BY property_valuation;

-- Проверим, есть ли нечисловые значения в property_valuation
SELECT property_valuation 
FROM customer 
WHERE property_valuation::text !~ '^[0-9]+$';

-- Преобразование online_order в BOOLEAN
ALTER TABLE orders 
ALTER COLUMN online_order TYPE BOOLEAN 
USING CASE 
    WHEN online_order = 'True' THEN true
    WHEN online_order = 'False' THEN false
    ELSE NULL
END;

-- Преобразование order_date в DATE (учитывая пустые значения)
ALTER TABLE orders 
ALTER COLUMN order_date TYPE DATE 
USING NULLIF(order_date, '')::DATE;

-- Преобразования для таблицы customer:
ALTER TABLE customer 
ALTER COLUMN date_of_birth TYPE DATE 
USING NULLIF(date_of_birth, '')::DATE;

-- Преобразование deceased_indicator в BOOLEAN
ALTER TABLE customer 
ALTER COLUMN deceased_indicator TYPE BOOLEAN 
USING CASE 
    WHEN deceased_indicator = 'Y' THEN true
    WHEN deceased_indicator = 'N' THEN false
    ELSE NULL
END;

-- Преобразование owns_car в BOOLEAN
ALTER TABLE customer 
ALTER COLUMN owns_car TYPE BOOLEAN 
USING CASE 
    WHEN owns_car = 'Yes' THEN true
    WHEN owns_car = 'No' THEN false
    ELSE NULL
END;

-- Преобразование property_valuation в INTEGER
ALTER TABLE customer 
ALTER COLUMN property_valuation TYPE INTEGER 
USING property_valuation::INTEGER;

-- Проверяем, что преобразование прошло успешно
SELECT 
    table_name,
    column_name, 
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('orders', 'customer')
ORDER BY table_name, ordinal_position;

-- Проверяем количество NULL значений после преобразования
SELECT 
    'orders.online_order' as field,
    COUNT(*) as total,
    SUM(CASE WHEN online_order IS NULL THEN 1 ELSE 0 END) as null_count
FROM orders
UNION ALL
SELECT 
    'orders.order_date',
    COUNT(*),
    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END)
FROM orders
UNION ALL
SELECT 
    'customer.date_of_birth',
    COUNT(*),
    SUM(CASE WHEN date_of_birth IS NULL THEN 1 ELSE 0 END)
FROM customer
UNION ALL
SELECT 
    'customer.deceased_indicator',
    COUNT(*),
    SUM(CASE WHEN deceased_indicator IS NULL THEN 1 ELSE 0 END)
FROM customer;

-- Распределение online_order (учитывая NULL)
SELECT 
    online_order,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 2) as percentage
FROM orders 
GROUP BY online_order 
ORDER BY online_order;

-- Проверим deceased_indicator (должно быть всего 2 true)
SELECT 
    deceased_indicator,
    COUNT(*) as count
FROM customer 
GROUP BY deceased_indicator;

-- Создадим ограничения для обеспечения целостности данных:
-- 1. Проверим, есть ли NULL в полях, которые хотим сделать NOT NULL
SELECT 
    COUNT(*) as total_orders,
    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) as null_order_date
FROM orders;

SELECT 
    COUNT(*) as total_customers,
    SUM(CASE WHEN deceased_indicator IS NULL THEN 1 ELSE 0 END) as null_deceased,
    SUM(CASE WHEN owns_car IS NULL THEN 1 ELSE 0 END) as null_owns_car,
    SUM(CASE WHEN property_valuation IS NULL THEN 1 ELSE 0 END) as null_property_valuation
FROM customer;

-- Добавляем NOT NULL ограничения где это уместно
alter table orders alter column order_date set not null
alter table customer alter column deceased_indicator set not null
alter table customer alter column owns_car set not null
ALTER TABLE customer ALTER COLUMN property_valuation SET NOT NULL

-- Добавляем первичные ключи:
alter table customer add primary key (customer_id)
alter table product add primary key (product_id) -- получили ошибку, имеем дубликаты 

-- Находим дублирующиеся product_id
SELECT 
    product_id,
    COUNT(*) as duplicate_count
FROM product
GROUP BY product_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Посмотрим сами дублирующиеся записи
SELECT *
FROM product
WHERE product_id IN (
    SELECT product_id
    FROM product
    GROUP BY product_id
    HAVING COUNT(*) > 1
)
ORDER BY product_id;

-- Проверим customer_id на дубликаты
SELECT 
    customer_id,
    COUNT(*) as duplicate_count
FROM customer
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Очень серьезная проблема! Дубликаты не идентичны - они имеют совершенно разные данные (бренды, категории, цены). 
-- Особенно проблемный product_id = 0, который используется для 19 разных продуктов!
-- Это указывает на серьезные проблемы с качеством данных. 

-- Проверим, используются ли дублирующиеся product_id в заказах
SELECT 
    oi.product_id,
    COUNT(DISTINCT oi.order_id) as order_count,
    COUNT(*) as item_count
FROM order_items oi
WHERE oi.product_id IN (
    SELECT product_id
    FROM product
    GROUP BY product_id
    HAVING COUNT(*) > 1
)
GROUP BY oi.product_id
ORDER BY item_count DESC;
--Критическая ситуация! Дублирующиеся product_id активно используются в заказах. 

-- Полный анализ использования продуктов
SELECT 
    p.product_id,
    COUNT(DISTINCT p.brand) as distinct_brands,
    COUNT(DISTINCT p.product_line) as distinct_lines,
    COUNT(*) as product_records,
    COUNT(DISTINCT oi.order_id) as orders_using_product,
    COUNT(oi.order_item_id) as total_order_items
FROM product p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id
HAVING COUNT(*) > 1 OR COUNT(DISTINCT p.brand) > 1
ORDER BY total_order_items DESC, product_records DESC;
-- Результаты показывают проблему с данными.
-- Анализ проблемы:
-- product_id = 0 имеет 26,182 записей в order_items 
-- это означает, что один product_id используется для множества разных продуктов в заказах
-- большинство дублирующихся product_id активно используются в заказах
-- Проблема масштабная - затрагивает множество продуктов

-- Создаем таблицу с действительно уникальными продуктами
CREATE TABLE product_clean (
    product_id SERIAL PRIMARY KEY,
    brand VARCHAR,
    product_line VARCHAR,
    product_class VARCHAR,
    product_size VARCHAR,
    list_price NUMERIC,
    standard_cost NUMERIC
);

-- Вставляем уникальные комбинации
INSERT INTO product_clean (brand, product_line, product_class, product_size, list_price, standard_cost)
SELECT DISTINCT 
    brand,
    product_line,
    product_class,
    product_size,
    list_price,
    standard_cost
FROM product
WHERE brand IS NOT NULL AND brand != ''
ORDER BY brand, product_line, product_class;

-- Проверяем
SELECT COUNT(*) as unique_products FROM product_clean;

SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Создаем новую таблицу с правильной структурой, так как в старой поехавший product_id
CREATE TABLE order_items_clean (
    order_item_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER,
    item_list_price_at_sale NUMERIC,
    item_standard_cost_at_sale NUMERIC
);

-- Вставляем данные с правильными product_id из product_clean
INSERT INTO order_items_clean (order_id, product_id, quantity, item_list_price_at_sale, item_standard_cost_at_sale)
SELECT 
    oi.order_id,
    pc.product_id,  -- используем новые уникальные ID из product_clean
    oi.quantity,
    oi.item_list_price_at_sale,
    oi.item_standard_cost_at_sale
FROM order_items oi
JOIN product p ON oi.product_id = p.product_id
JOIN product_clean pc ON p.brand = pc.brand 
                      AND p.product_line = pc.product_line 
                      AND p.product_class = pc.product_class 
                      AND p.product_size = pc.product_size
                      AND p.list_price = pc.list_price
                      AND p.standard_cost = pc.standard_cost;

-- Удаляем старую таблицу products
DROP TABLE product;

-- Переименовываем product_clean в product
ALTER TABLE product_clean RENAME TO product;

-- Удаляем старую проблемную таблицу
DROP TABLE order_items;

ALTER TABLE order_items_clean RENAME TO order_items;

-- Проверяем существующие первичные ключи
SELECT
    tc.table_name,
    kc.column_name,
    tc.constraint_type
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kc 
    ON tc.constraint_name = kc.constraint_name
WHERE tc.table_schema = 'public'
AND tc.table_name IN ('customer', 'product', 'orders', 'order_items')
AND tc.constraint_type = 'PRIMARY KEY'
ORDER BY tc.table_name;
    
-- Проверяем, можно ли сделать order_id первичным ключом
SELECT 
    order_id,
    COUNT(*) as duplicate_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC
LIMIT 10;

SELECT COUNT(*) as null_order_id_count
FROM orders 
WHERE order_id IS NULL;

-- Смотрим, какие заказы имеют несуществующих клиентов
SELECT 
    o.order_id,
    o.customer_id,
    o.order_date
FROM orders o
LEFT JOIN customer c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL; -- опять призрак 5034

-- добавляем 5034 
INSERT INTO customer (
    customer_id,
    first_name,
    last_name,
    deceased_indicator,
    owns_car,
    property_valuation
) VALUES (
    5034,
    'Unknown',
    'Customer',
    false,
    false,
    1
);

-- 1. Добавляем первичный ключ для orders (если еще нет)
ALTER TABLE orders ADD PRIMARY KEY (order_id);

-- 2. orders → customer
ALTER TABLE orders 
ADD CONSTRAINT fk_orders_customer 
FOREIGN KEY (customer_id) REFERENCES customer(customer_id);

-- 3. order_items → orders  
ALTER TABLE order_items 
ADD CONSTRAINT fk_order_items_orders 
FOREIGN KEY (order_id) REFERENCES orders(order_id);

-- 4. order_items → product
ALTER TABLE order_items 
ADD CONSTRAINT fk_order_items_product 
FOREIGN KEY (product_id) REFERENCES product(product_id);

CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_orders_order_date ON orders(order_date);

-- Проверяем все ограничения
SELECT
    tc.table_name,
    kc.column_name,
    tc.constraint_type,
    tc.constraint_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kc 
    ON tc.constraint_name = kc.constraint_name
WHERE tc.table_schema = 'public'
AND tc.table_name IN ('customer', 'product', 'orders', 'order_items')
ORDER BY tc.table_name, tc.constraint_type;

-- Проверяем, что нет "осиротевших" записей
SELECT 
    'orders without customers' as issue,
    COUNT(*) as count
FROM orders o
LEFT JOIN customer c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL

UNION ALL

SELECT 
    'order_items without orders',
    COUNT(*)
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT 
    'order_items without products',
    COUNT(*)
FROM order_items oi
LEFT JOIN product p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Еще раз проверка количества записей во всех таблицах. Запускаем ранее написаный скрипт

-- Я допустил ошибку: теперь в order_items ~57 000 записей вместо 20 000
-- Что произошло: я создал новые уникальные ID для продуктов, но при связывании с заказами 
-- одна исходная запись заказа стала ссылаться на несколько новых продуктов вместо одного.
-- Результат: Количество записей в заказах увеличилось в ~3 раза, так как один старый product_id 
-- соответствовал нескольким новым продуктам с разными атрибутами.
-- Как исправить: создать новую таблицу заказов из CSV, используя сурогатные ключи и правильные связи с продуктами.

-- Удаляем текущую таблицу
DROP TABLE order_items;

-- Создаем чистую таблицу с сурогатным ключом
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY, 
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER,
    item_list_price_at_sale NUMERIC,
    item_standard_cost_at_sale NUMERIC
);

-- залили заново данные из исходной CVS, сгенерировав order_item_id с помощью SERIAL
SELECT COUNT(*) FROM order_items; -- порядок, 20 000 записей

-- Проверяем автоматическую генерацию ID
SELECT MIN(order_item_id), MAX(order_item_id), COUNT(*) 
FROM order_items; -- порядок: min -1, max - 20 000, count - 20 000

-- order_items → orders
ALTER TABLE order_items 
ADD CONSTRAINT fk_order_items_orders 
FOREIGN KEY (order_id) REFERENCES orders(order_id);

ALTER TABLE order_items 
ADD CONSTRAINT fk_order_items_product 
FOREIGN KEY (product_id) REFERENCES product(product_id); -- получили ошибку, Ключ (product_id)=(0) отсутствует в таблице "product".

-- Смотрим сколько таких записей
SELECT COUNT(*) 
FROM order_items oi
LEFT JOIN product p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL; -- 1 378

-- В исходном CSV файле product_id = 0 используется для 19 разных продуктов с разными брендами, категориями и ценами!
-- Когда мы делали SELECT DISTINCT ... для создания product_clean, мы получили только уникальные комбинации атрибутов, 
-- но потеряли информацию о том, что все они были с product_id = 0.
-- Моя "очистка" была правильной, но исходные данные содержали фундаментальную ошибку - один ID для разных сущностей.
-- Лучшее решение: сделать "Unknown Product" для product_id = 0, чтобы сохранить исторические заказы.

-- Оставляем одну запись для product_id = 0
INSERT INTO product (product_id, brand, product_line, product_class, product_size, list_price, standard_cost)
VALUES (0, 'Unknown Brand', 'Unknown Product', 'Unknown', 'Unknown', 0, 0);

-- Настраиваем внешний ключ
ALTER TABLE order_items 
ADD CONSTRAINT fk_order_items_product  
FOREIGN KEY (product_id) REFERENCES product(product_id);

-- Сумма заказов с product_id = 0
SELECT 
    COUNT(*) as order_count,
    SUM(quantity) as total_quantity,
    ROUND(SUM(quantity * item_list_price_at_sale), 2) as total_revenue,
    ROUND(SUM(quantity * item_standard_cost_at_sale), 2) as total_cost,
    ROUND(SUM(quantity * item_list_price_at_sale - quantity * item_standard_cost_at_sale), 2) as total_profit
FROM order_items 
WHERE product_id = 0;

-- В общих отчетах product_id = 0 будет участвовать
SELECT 
    CASE 
        WHEN p.product_id = 0 THEN 'Unknown Products'
        ELSE 'Regular Products'
    END as product_type,
    COUNT(*) as order_count,
    ROUND(SUM(oi.quantity * oi.item_list_price_at_sale), 2) as revenue
FROM order_items oi
JOIN product p ON oi.product_id = p.product_id
GROUP BY product_type;

-- Еще раз запускаем все предыдущие проверки, сколько записей во всех таблицах, нет ли "осиротевщих записей"
-- Запускаем ранее написанные скрипты. Все хорошо!
-- Еще проверим наличие всех внешних ключей
SELECT
    tc.table_name,
    kc.column_name,
    tc.constraint_type,
    tc.constraint_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kc 
    ON tc.constraint_name = kc.constraint_name
WHERE tc.table_schema = 'public'
AND tc.table_name IN ('customer', 'product', 'orders', 'order_items')
AND tc.constraint_type = 'FOREIGN KEY'
ORDER BY tc.table_name;

-- Теперь база данных полностью настроена и прошла все проверки. 
-- Можно начинать анализировать данные.

SELECT DISTINCT p.brand
FROM product p
JOIN order_items oi ON p.product_id = oi.product_id
WHERE p.standard_cost > 1500
GROUP BY p.brand
HAVING SUM(oi.quantity) >= 1000;

SELECT 
    order_date,
    COUNT(*) as order_count,
    COUNT(DISTINCT customer_id) as unique_customers
FROM orders
WHERE order_date BETWEEN '2017-04-01' AND '2017-04-09'
    AND online_order = true
    AND order_status = 'Approved'
GROUP BY order_date
ORDER BY order_date;

SELECT 
    job_title,
    job_industry_category,
    date_of_birth
FROM customer
WHERE job_industry_category = 'IT' 
    AND job_title LIKE 'Senior%'
    AND EXTRACT(YEAR FROM AGE(current_date, date_of_birth)) > 35

UNION ALL

SELECT 
    job_title,
    job_industry_category,
    date_of_birth
FROM customer
WHERE job_industry_category = 'Financial Services' 
    AND job_title LIKE 'Lead%'
    AND EXTRACT(YEAR FROM AGE(current_date, date_of_birth)) > 35;

SELECT DISTINCT p.brand
FROM product p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
JOIN customer c ON o.customer_id = c.customer_id
WHERE c.job_industry_category = 'Financial Services'
EXCEPT
SELECT DISTINCT p.brand
FROM product p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
JOIN customer c ON o.customer_id = c.customer_id
WHERE c.job_industry_category = 'IT';

SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(*) as order_count
FROM customer c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id  
JOIN product p ON oi.product_id = p.product_id
WHERE o.online_order = true
    AND c.deceased_indicator = false
    AND c.property_valuation > (SELECT AVG(property_valuation) FROM customer WHERE state = c.state)
    AND p.brand IN ('Giant Bicycles', 'Norco Bicycles', 'Trek Bicycles')
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY order_count DESC
LIMIT 10;

SELECT 
    customer_id,
    first_name,
    last_name
FROM customer
WHERE owns_car = true
    AND wealth_segment != 'Mass Customer'
    AND customer_id NOT IN (
        SELECT DISTINCT customer_id 
        FROM orders 
        WHERE online_order = true 
            AND order_status = 'Approved'
            AND order_date >= CURRENT_DATE - INTERVAL '1 year'
    );

WITH top_road_products AS (
    SELECT product_id
    FROM product
    WHERE product_line = 'Road'
    ORDER BY list_price DESC
    LIMIT 5
)
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name
FROM customer c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE c.job_industry_category = 'IT'
    AND oi.product_id IN (SELECT product_id FROM top_road_products)
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(DISTINCT oi.product_id) >= 2;

SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.job_industry_category
FROM customer c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE c.job_industry_category = 'IT'
    AND o.order_status = 'Approved'
    AND o.order_date BETWEEN '2017-01-01' AND '2017-03-01'
GROUP BY c.customer_id, c.first_name, c.last_name, c.job_industry_category
HAVING COUNT(DISTINCT o.order_id) >= 3
    AND SUM(oi.quantity * oi.item_list_price_at_sale) > 10000
UNION
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.job_industry_category
FROM customer c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE c.job_industry_category = 'Health'
    AND o.order_status = 'Approved'
    AND o.order_date BETWEEN '2017-01-01' AND '2017-03-01'
GROUP BY c.customer_id, c.first_name, c.last_name, c.job_industry_category
HAVING COUNT(DISTINCT o.order_id) >= 3
    AND SUM(oi.quantity * oi.item_list_price_at_sale) > 10000;


