--My SQL query solutions for various problems.

--1.Customers Table - This table stores customer information.
--2. Products Table - This table stores product details.
--3.Orders Table - This table stores information about customer orders.
--4. OrderItems Table - This table represents products purchased in each order.



--Customers Table Columns:

/*	customer id - PRIMARY KEY
	customer name
	email
	phone number
	address
	registration date    */
	
--Products Table Columns:

/*	product id - PRIMARY KEY
	product name
	description
	price
	stock quantity
	category
	date added      */

--Orders Table Columns:

/*	order id -  PRIMARY KEY
	customer id - foreign key
	order date
	total amount
	status          */

--OrderItems Table Columns:

/*	order item id -PRIMARY KEY
	order id - foreign key
	product id - foreign key
	quantity
	price           */



-- QUERIES AND SOLUTION:

--1. Retrieve all customer details.
SELECT * FROM Customers;

--2. Retrieve all products with a price greater than 100.
SELECT * FROM Products WHERE price > 100;

--3. Retrieve the names of customers along with the products they ordered.
SELECT c.customer_name, p.product_name 
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
JOIN OrderItems oi ON o.order_id = oi.order_id
JOIN Products p ON oi.product_id = p.product_id;

--4. Retrieve the total number of orders placed by each customer.
SELECT c.customer_id, c.customer_name, COUNT(o.order_id) AS total_orders
FROM Customers c
LEFT JOIN Orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name;

--5. Retrieve the total amount spent by each customer.
SELECT c.customer_id, c.customer_name, SUM(o.total_amount) AS total_spent
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name;

--6. Retrieve products sorted by their price in descending order.
SELECT * FROM Products ORDER BY price DESC;

--7. Find the customers who have placed an order totaling more than 200.
SELECT c.customer_id, c.customer_name
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
WHERE o.total_amount > 200;

--8. Retrieve products that have less than 10 units available in stock.
SELECT * FROM Products WHERE stock_quantity < 10;

--9. Retrieve orders where the total amount is between 100 and 500.
SELECT * FROM Orders WHERE total_amount BETWEEN 100 AND 500;

--10. Retrieve products that have been ordered in the last 30 days, including product name and quantity ordered.
SELECT p.product_name, SUM(oi.quantity) AS total_quantity_ordered
FROM Products p
JOIN OrderItems oi ON p.product_id = oi.product_id
JOIN Orders o ON oi.order_id = o.order_id
WHERE o.order_date >= DATEADD(DAY, -30, GETDATE())
GROUP BY p.product_name;

--11. Retrieve customers who have placed more than 1 order.
SELECT c.customer_id, c.customer_name
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(o.order_id) > 1;

--12. Calculate the average order value for each customer
SELECT c.customer_id, c.customer_name, AVG(o.total_amount) AS avg_order_value
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name;

--13. Retrieve orders that contain more than one product.
SELECT o.order_id
FROM Orders o
JOIN OrderItems oi ON o.order_id = oi.order_id
GROUP BY o.order_id
HAVING COUNT(oi.product_id) > 1;

--14. Find Orders with Discounts Greater Than 20% (Using a Function)
CREATE FUNCTION GetDiscountedOrders()
RETURNS TABLE
AS
RETURN (
    SELECT order_id, total_amount, (total_amount * 0.2) AS discount
    FROM Orders
    WHERE total_amount * 0.2 > 20
);
GO

SELECT * FROM dbo.GetDiscountedOrders();

--15. Create a stored procedure to add a new product.
CREATE PROCEDURE AddNewProduct
    @product_name VARCHAR(255),
    @description TEXT,
    @price DECIMAL(10,2),
    @stock_quantity INT,
    @category VARCHAR(255),
    @date_added DATE
AS
BEGIN
    INSERT INTO Products (product_name, description, price, stock_quantity, category, date_added)
    VALUES (@product_name, @description, @price, @stock_quantity, @category, @date_added);
END;
GO

--16. Create a trigger to update product stock when an order is placed,
CREATE TRIGGER UpdateStockOnOrder
ON OrderItems
AFTER INSERT
AS
BEGIN
    UPDATE Products
    SET stock_quantity = stock_quantity - (SELECT quantity FROM inserted WHERE inserted.product_id = Products.product_id)
    FROM Products
    JOIN inserted ON Products.product_id = inserted.product_id;
END;
GO


--17. Create a function to calculate a discount based on the total order amount.
CREATE FUNCTION CalculateDiscount (@total_amount DECIMAL(10,2))
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @discount DECIMAL(10,2);
    IF @total_amount > 500
        SET @discount = @total_amount * 0.15;
    ELSE IF @total_amount > 200
        SET @discount = @total_amount * 0.10;
    ELSE
        SET @discount = @total_amount * 0.05;
    RETURN @discount;
END;
GO

--18. Create a Stored procedure to update the order status to "Shipped" once the order is shipped.
CREATE PROCEDURE UpdateOrderStatusToShipped
    @order_id INT
AS
BEGIN
    UPDATE Orders
    SET status = 'Shipped'
    WHERE order_id = @order_id;
END;
GO

--19. Create a trigger that prevents order if stock quantity is 0.
CREATE TRIGGER PreventZeroStockOrder
ON OrderItems
BEFORE INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM Products p
        JOIN inserted i ON p.product_id = i.product_id
        WHERE p.stock_quantity = 0
    )
    BEGIN
        RAISERROR ('Cannot place order, product is out of stock.', 16, 1);
        ROLLBACK;
    END;
END;
GO

--20. Delete Products with No Orders.
DELETE FROM Products
WHERE product_id NOT IN (SELECT DISTINCT product_id FROM OrderItems);



