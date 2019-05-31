-- Script for project 
USE CS669

DROP TABLE BrandNewSneaker;
DROP TABLE PreOwnedSneaker;
DROP TABLE PriceChange;
DROP TABLE Sneaker;
DROP TABLE SneakersForSale;
DROP TABLE Inventory;
DROP TABLE FreeAccount;
DROP TABLE PremiumAccount;
DROP TABLE Account;

drop procedure AddFreeAccount
drop procedure AddNewSneaker
drop PROCEDURE SellSneaker

drop trigger PriceChangeTrigger

-- Table Creation
CREATE TABLE Account(
account_id INT NOT NULL PRIMARY KEY,
Username VARCHAR(64) NOT NULL,
Password VARCHAR(255) NOT NULL,
FirstName VARCHAR(255) NOT NULL,
LastName VARCHAR(255) NOT NULL,
EmailAddress VARCHAR(255) NOT NULL,
PhoneNumber VARCHAR(10) NOT NULL,
AccountType CHAR(1) NOT NULL);

CREATE TABLE FreeAccount(
account_id INT NOT NULL PRIMARY KEY,
FOREIGN KEY (account_id) REFERENCES Account(account_id)
);

CREATE TABLE PremiumAccount(
account_id INT NOT NULL PRIMARY KEY,
AccountBalance DECIMAL(7,2) NOT NULL,
PaymentDue DATE NOT NULL,
FOREIGN KEY (account_id) REFERENCES Account(account_id)
);

CREATE TABLE SneakersForSale(
sneakers_for_sale_id INT NOT NULL PRIMARY KEY,
account_id INT NOT NULL, 
SneakerQuantity INT,  
TotalAskValue DECIMAL(12,2)
FOREIGN KEY (account_id) REFERENCES Account(account_id)
);

CREATE TABLE Inventory(
inventory_id INT NOT NULL PRIMARY KEY,
account_id INT NOT NULL, 
SneakerQuantity INT, 
TotalValue DECIMAL(12,2)
FOREIGN KEY (account_id) REFERENCES Account(account_id)
);


CREATE TABLE Sneaker(
sneaker_id  INT NOT NULL PRIMARY KEY, 
inventory_id INT NOT NULL, 
sneakers_for_sale_id INT, 
Brand VARCHAR(64) NOT NULL,
ProductLine VARCHAR(64) NOT NULL,
Size DECIMAL(3,1) NOT NULL,
ColorWay VARCHAR(64) NOT NULL,
PurchaseDate DATE NOT NULL, 
PurchasePrice DECIMAL(7,2) NOT NULL,
SneakerType CHAR(1) NOT NULL,
SellingDate DATE, 
SellingPrice DECIMAL(7,2) ,
ProfitOrLoss DECIMAL(7,2) ,
ProfitMargin DECIMAL(7,2) ,
DaysInHand INT
FOREIGN KEY (inventory_id) REFERENCES Inventory(inventory_id),
FOREIGN KEY (sneakers_for_sale_id) REFERENCES SneakersForSale(sneakers_for_sale_id)
);

CREATE TABLE BrandNewSneaker(
sneaker_id  INT NOT NULL PRIMARY KEY, 
FOREIGN KEY (sneaker_id) REFERENCES Sneaker(sneaker_id)
);

CREATE TABLE PreOwnedSneaker(
sneaker_id  INT NOT NULL PRIMARY KEY, 
Condition VARCHAR(64) NOT NULL,
FOREIGN KEY (sneaker_id) REFERENCES Sneaker(sneaker_id)
);


-- index creation on Foreign keys
CREATE UNIQUE INDEX InventoryAccountIdx
ON Inventory(account_id)

CREATE UNIQUE INDEX SneakersForSaleAccountIdx
ON SneakersForSale(account_id)

CREATE INDEX SneakerInventoryIdx
ON Sneaker(inventory_id)

CREATE INDEX SneakerSneakersForSaleIdx
ON Sneaker(sneakers_for_sale_id)


--index creation on 3 chosen queries
--query 1 Find Inventory by Total Value
CREATE INDEX InventoryTotalValueIdx
ON Inventory(TotalValue)

-- Query 2 - Find Sneaker by Brand
CREATE INDEX SneakerBrandIdx
ON Sneaker(Brand)

-- Query 3 - Find Sneaker by Purchase Date
CREATE INDEX SneakerPurchaseDate
ON Sneaker(PurchaseDate)


-- stored procedure creation
-- account login use case
CREATE PROCEDURE AddFreeAccount 
@account_id INT ,
@Username VARCHAR(64) ,
@Password VARCHAR(255) ,
@FirstName VARCHAR(255) ,
@LastName VARCHAR(255) ,
@EmailAddress VARCHAR(255) ,
@PhoneNumber VARCHAR(10)
AS
BEGIN
	INSERT INTO Account(account_id, UserName, Password, FirstName, LastName, 
				EmailAddress, PhoneNumber, AccountType)
	Values(@account_id ,@Username ,@Password,@FirstName,
		@LastName ,@EmailAddress , @PhoneNumber, 'F')  -- F = free , P = premium

	INSERT INTO FreeAccount(account_id)
	Values(@account_id)
END;
GO

-- create buy sneaker use case
CREATE PROCEDURE AddNewSneaker
@account_id INT,
@sneaker_id  INT  , 
@Brand VARCHAR(64) ,
@ProductLine VARCHAR(64) ,
@Size DECIMAL(3,1) ,
@ColorWay VARCHAR(64) ,
@PurchaseDate DATE , 
@PurchasePrice DECIMAL(7,2) ,
@SneakerType CHAR(1)   -- N = new, P = Pre-owned
AS
BEGIN
	if not exists (SELECT* FROM Inventory where account_id = @account_id)
		BEGIN
			INSERT INTO Inventory(inventory_id, account_id, SneakerQuantity, TotalValue)
			VALUES(ISNULL((SELECT MAX(inventory_id)+1 FROM Inventory), 1)
					, @account_id, null, null);
		END

	DECLARE @v_inventory_id DECIMAL(12);
	SELECT @v_inventory_id = Inventory.inventory_id FROM Inventory where Inventory.account_id = @account_id;

	BEGIN
		INSERT INTO Sneaker(sneaker_id, inventory_id, sneakers_for_sale_id, 
							Brand, ProductLine, Size, ColorWay,
							PurchaseDate, PurchasePrice, SneakerType, 
							SellingDate,SellingPrice, ProfitOrLoss, ProfitMargin, DaysInHand) -- this row nullable
		VALUES(@sneaker_id, @v_inventory_id, NULL, @Brand ,@ProductLine,@Size,@ColorWay,
				@PurchaseDate , @PurchasePrice, 'N', NULL, NULL, NULL, NULL, NULL )

		INSERT INTO BrandNewSneaker(sneaker_id)
		VALUES(@sneaker_id)
	END
END

-- create sell sneaker use case
CREATE PROCEDURE SellSneaker
@account_id INT,
@sneaker_id  INT, 
@SellingDate DATE, 
@SellingPrice DECIMAL(7,2)
AS 
BEGIN
	if not exists (SELECT* FROM SneakersForSale where account_id = @account_id)
		BEGIN
			INSERT INTO SneakersForSale(sneakers_for_sale_id, account_id, SneakerQuantity, TotalAskValue)
			VALUES(ISNULL((SELECT MAX(sneakers_for_sale_id)+1 FROM SneakersForSale), 1)
					, @account_id, null, null);
		END

	DECLARE @v_profit_or_loss DECIMAL(7,2), 
			@v_progit_margin DECIMAL(7,2),
			@v_PurchasePrice DECIMAL(7,2), 
			@v_purchaseDate DATE,
			@v_dateDiff INT,
			@sneakers_for_sale_id INT;

	SELECT @v_PurchasePrice = Sneaker.PurchasePrice FROM Sneaker where sneaker_id = Sneaker.sneaker_id ;
	SELECT @v_purchaseDate = Sneaker.PurchaseDate FROM Sneaker where sneaker_id = Sneaker.sneaker_id ;
	SELECT @v_profit_or_loss = @SellingPrice - @v_PurchasePrice 
	SELECT @v_progit_margin = @v_profit_or_loss/@v_PurchasePrice * 100
	SELECT @v_dateDiff = DATEDIFF(day, @v_purchaseDate, @SellingDate)
	SELECT @sneakers_for_sale_id = SneakersForSale.sneakers_for_sale_id FROM SneakersForSale where SneakersForSale.account_id = @account_id

	Begin 
		UPDATE Sneaker
		SET SellingDate = @SellingDate, SellingPrice = @SellingPrice, 
			ProfitOrLoss = @v_profit_or_loss, ProfitMargin = @v_progit_margin,
			sneakers_for_sale_id = @sneakers_for_sale_id,
			DaysInHand = @v_dateDiff
		WHERE Sneaker.sneaker_id = @sneaker_id
	END
END


-- Table for storing price change history
CREATE TABLE PriceChange(
price_change_id INT NOT NULL PRIMARY KEY,
OldPrice DECIMAL(7,2) NOT NULL ,
NewPrice DECIMAL(7,2) NOT NULL ,
sneaker_id INT NOT NULL ,
ChangeDate DATE NOT NULL 
FOREIGN KEY(sneaker_id) REFERENCES Sneaker(sneaker_id)
);


--PriceChange Trigger
CREATE TRIGGER PriceChangeTrigger
ON Sneaker
After UPDATE
AS
BEGIN
	DECLARE @v_old_selling_price DECIMAL(7,2) = (SELECT SellingPrice FROM DELETED);
	DECLARE @v_new_selling_price DECIMAL(7,2) = (SELECT SellingPrice FROM INSERTED);

	IF (@v_old_selling_price <> @v_new_selling_price)
		INSERT INTO PriceChange (price_change_id, OldPrice, NewPrice, sneaker_id, ChangeDate)
		VALUES (ISNULL((SELECT MAX(price_change_id)+1 FROM PriceChange), 1),
				@v_old_selling_price,
				@v_new_selling_price,
				(SELECT sneaker_id FROM INSERTED),
				GETDATE());
END


-- insert data to database 
-- create a bunch of account 6 free and 3 premium in total
BEGIN TRANSACTION AddFreeAccount;
EXECUTE AddFreeAccount 1, 'sneaker_boss', 'sneaker1234', 'Chris', 'Evan', 'cevan@marvel.com', '5623759854';
EXECUTE AddFreeAccount 2, 'achan', 'noideawhatpasswordtoset', 'anthony', 'chan', 'achan@gmail.com', '9896544546';
EXECUTE AddFreeAccount 3, 'scurry', 'Ionlyshootthrees', 'stephen', 'curry', 'scurry@warriros.com', '5648564521';
EXECUTE AddFreeAccount 4, 'ljames', 'iamking', 'lebron', 'james', 'ljames@lakers.com', '4565789654';
EXECUTE AddFreeAccount 5, 'jwang', 'teamwang', 'jackson', 'wang', 'jwang@teamwang.com', '6264585463';
EXECUTE AddFreeAccount 6, 'slee', 'marvelisthebest', 'stan', 'lee', 'slee@marvel.com', '6569894569';
COMMIT TRANSACTION AddFreeAccount;

INSERT INTO Account(account_id, UserName, Password, FirstName, LastName, 
				EmailAddress, PhoneNumber, AccountType)
Values
(7 , 'kwest' ,'imadeyeezy','kayne', 'west' ,'kwest@yeezysupply.com' , '9884568888', 'P'),  -- F = free , P = premium
(8 , 'tstark' ,'imironman','tony', 'stark' ,'tstark@marvel.com' , '5374658971', 'P') ,
(9 , 'ukim' ,'iliveinkorea','un', 'kim' ,'unkim@korea.com' , '4531987546', 'P') ;


-- creat a bunch of sneakers
BEGIN TRANSACTION AddNewSneaker
EXECUTE AddNewSneaker 1, 1, 'Adidas', 'Yeezy', 11.5, 'Cream', '02-01-2018', 240, 'N';
EXECUTE AddNewSneaker 2, 2, 'Adidas', 'Yeezy', 5.5, 'Cream', '02-01-2018', 220, 'N';
EXECUTE AddNewSneaker 2, 3, 'Adidas', 'Yeezy', 6.5, 'Blue Tint', '03-01-2018', 220, 'N';
EXECUTE AddNewSneaker 2, 4, 'Adidas', 'Yeezy', 7.5, 'Static', '04-01-2018', 220, 'N';
EXECUTE AddNewSneaker 3, 5, 'Adidas', 'Yeezy', 8.5, 'Clay', '05-01-2018', 220, 'N';
EXECUTE AddNewSneaker 4, 6, 'Adidas', 'Yeezy', 9.5, 'Hyperspace', '06-01-2018', 220, 'N';
EXECUTE AddNewSneaker 5, 7, 'Adidas', 'Yeezy', 10.5, 'Trueform', '07-01-2018', 220, 'N';
EXECUTE AddNewSneaker 6, 8, 'Adidas', 'Yeezy', 11.5, 'Zebra', '02-01-2017', 220, 'P';
EXECUTE AddNewSneaker 6, 9, 'Adidas', 'Yeezy', 8, 'Butter', '03-01-2017', 220, 'P';
EXECUTE AddNewSneaker 6,10, 'Nike', 'Jordan 1 Retro High', 9, 'Not For Resale', '04-01-2017', 160, 'P';
EXECUTE AddNewSneaker 9,11, 'Nike', 'Jordan 1 Retro High', 7, 'Turbo Green', '02-01-2016', 160, 'P';
EXECUTE AddNewSneaker 9,12, 'Nike', 'Jordan 1 Retro High', 13, 'Phantom Gym', '02-01-2015', 160, 'P';
EXECUTE AddNewSneaker 9,13, 'Nike', 'Jordan 1 Retro High', 5, 'UNC Patent', '02-01-2014', 160, 'P';
EXECUTE AddNewSneaker 2,14, 'Nike', 'Jordan 1 Retro High', 5, 'UNC Patent', '02-01-2017', 160, 'F';

COMMIT TRANSACTION AddNewSneaker;


-- sell sneakers, these will update the price change table.
BEGIN TRANSACTION SellSneaker
EXECUTE SellSneaker 5, 7, '09-01-2018', 8800;
EXECUTE SellSneaker 6, 8, '10-01-2018', 1690;
EXECUTE SellSneaker 7, 9, '11-01-2018', 1100;

EXECUTE SellSneaker 5, 7, '09-01-2018', 8900;
EXECUTE SellSneaker 6, 8, '10-01-2018', 1790;
EXECUTE SellSneaker 7, 9, '11-01-2018', 1200;

EXECUTE SellSneaker 5, 7, '09-01-2018', 9000;
EXECUTE SellSneaker 6, 8, '10-01-2018', 1890;
EXECUTE SellSneaker 7, 9, '11-01-2018', 1300;

EXECUTE SellSneaker 2, 2, '11-01-2018', 420;
COMMIT TRANSACTION SellSneaker;


-- This query answers this question:
-- How many FreeAccount have at least 3 Sneaker in their Inventory ?
SELECT Account.account_id, username, COUNT(Account.account_id) as SneakerQuantity, AccountType
FROM Inventory
JOIN Account ON Inventory.account_id = Account.account_id
JOIN Sneaker ON Sneaker.inventory_id = Inventory.inventory_id
where AccountType = 'F'
GROUP BY Account.account_id, username, AccountType
Having COUNT(Account.account_id)>=3



-- This query answers this question:
-- How many Sneaker ProductLine in Inventory have TotalValue over $1500?
SELECT Brand, ProductLine, SUM(PurchasePrice) as TotalValue   
FROM Inventory
JOIN Sneaker ON Sneaker.inventory_id = Inventory.inventory_id
GROUP BY ProductLine, Brand
Having SUM(PurchasePrice) >= 1500


-- This query answers this question:
-- How many Sneaker in PriceChange table that made at least 2 changes are related to FreeAccount?
SELECT Sneaker.ProductLine, Sneaker.ColorWay, PriceChange.sneaker_id, Count(PriceChange.sneaker_id) as NumberOfPriceChange
From Sneaker
Join PriceChange ON PriceChange.sneaker_id = Sneaker.sneaker_id  
GROUP BY ProductLine, ColorWay, PriceChange.sneaker_id
Having Count(PriceChange.sneaker_id) >=2


