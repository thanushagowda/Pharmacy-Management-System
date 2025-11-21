SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS sales_items;
DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS purchase;
DROP TABLE IF EXISTS meds;
DROP TABLE IF EXISTS suppliers;
DROP TABLE IF EXISTS emplogin;
DROP TABLE IF EXISTS employee;
DROP TABLE IF EXISTS admin;
DROP TABLE IF EXISTS customer;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE suppliers (
  Sup_ID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  Sup_Name VARCHAR(100) NOT NULL,
  Sup_Add VARCHAR(255),
  Sup_Phone VARCHAR(20),
  Sup_Mail VARCHAR(100)
) ENGINE=InnoDB;

CREATE TABLE meds (
  Med_ID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  Med_Name VARCHAR(150) NOT NULL,
  Med_Qty INT NOT NULL DEFAULT 0,
  Category VARCHAR(50),
  Med_Price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  Location_Rack VARCHAR(50)
) ENGINE=InnoDB;

CREATE TABLE customer (
  C_ID INT NOT NULL PRIMARY KEY,
  C_Fname VARCHAR(100),
  C_Lname VARCHAR(100),
  C_Age INT,
  C_Sex CHAR(1),
  C_Phno VARCHAR(20),
  C_Mail VARCHAR(100)
) ENGINE=InnoDB;

CREATE TABLE employee (
  E_ID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  E_Fname VARCHAR(100),
  E_Lname VARCHAR(100),
  E_Bdate DATE,
  E_Age INT,
  E_Sex CHAR(1),
  E_Type VARCHAR(50),
  E_Date DATE,
  E_Add VARCHAR(255),
  E_Mail VARCHAR(100),
  E_Phone VARCHAR(20),
  E_Sal DECIMAL(10,2)
) ENGINE=InnoDB;

CREATE TABLE emplogin (
  E_Username VARCHAR(80) PRIMARY KEY,
  E_Password VARCHAR(255) NOT NULL,
  E_ID INT,
  FOREIGN KEY (E_ID) REFERENCES employee(E_ID)
      ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE admin (
  A_Username VARCHAR(80) PRIMARY KEY,
  A_Password VARCHAR(255) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE purchase (
  P_ID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  Med_ID INT NOT NULL,
  Sup_ID INT,
  P_Qty INT NOT NULL,
  P_Cost DECIMAL(10,2),
  P_Date DATE,
  Mfg_Date DATE,
  Exp_Date DATE,
  FOREIGN KEY (Med_ID) REFERENCES meds(Med_ID)
      ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (Sup_ID) REFERENCES suppliers(Sup_ID)
      ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE sales (
  SALE_ID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  S_Date DATE DEFAULT (CURRENT_DATE),
  S_Time TIME DEFAULT (CURRENT_TIME),
  TOTAL_AMT DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  C_ID INT,
  E_ID INT,
  FOREIGN KEY (C_ID) REFERENCES customer(C_ID)
        ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY (E_ID) REFERENCES employee(E_ID)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE sales_items (
  SALE_ITEM_ID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  SALE_ID INT NOT NULL,
  MED_ID INT NOT NULL,
  SALE_QTY INT NOT NULL DEFAULT 1,
  TOT_PRICE DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  FOREIGN KEY (SALE_ID) REFERENCES sales(SALE_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (MED_ID) REFERENCES meds(Med_ID)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_sales_CID ON sales (C_ID);
CREATE INDEX idx_sales_EID ON sales (E_ID);
CREATE INDEX idx_sales_items_sale ON sales_items (SALE_ID);
CREATE INDEX idx_sales_items_med ON sales_items (MED_ID);

DELIMITER $$
DROP FUNCTION IF EXISTS fn_sale_total $$
CREATE FUNCTION fn_sale_total(p_sale_id INT)
RETURNS DECIMAL(12,2)
DETERMINISTIC
BEGIN
  DECLARE v_total DECIMAL(12,2) DEFAULT 0.00;
  SELECT COALESCE(SUM(TOT_PRICE),0.00) INTO v_total
  FROM sales_items WHERE SALE_ID = p_sale_id;
  RETURN v_total;
END $$
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS trg_si_bi_set_tot_price $$
CREATE TRIGGER trg_si_bi_set_tot_price
BEFORE INSERT ON sales_items
FOR EACH ROW
BEGIN
  DECLARE v_price DECIMAL(10,2);
  SELECT Med_Price INTO v_price FROM meds WHERE Med_ID = NEW.MED_ID;
  SET NEW.TOT_PRICE = COALESCE(v_price,0.00) * NEW.SALE_QTY;
END $$
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS trg_si_ai_update_stock_total $$
CREATE TRIGGER trg_si_ai_update_stock_total
AFTER INSERT ON sales_items
FOR EACH ROW
BEGIN
  UPDATE meds SET Med_Qty = GREATEST(Med_Qty - NEW.SALE_QTY, 0)
    WHERE Med_ID = NEW.MED_ID;
  UPDATE sales SET TOTAL_AMT = fn_sale_total(NEW.SALE_ID)
    WHERE SALE_ID = NEW.SALE_ID;
END $$
DELIMITER ;

DELIMITER $$
DROP TRIGGER IF EXISTS trg_si_ad_restore_stock_total $$
CREATE TRIGGER trg_si_ad_restore_stock_total
AFTER DELETE ON sales_items
FOR EACH ROW
BEGIN
  UPDATE meds SET Med_Qty = Med_Qty + OLD.SALE_QTY
    WHERE Med_ID = OLD.MED_ID;
  UPDATE sales SET TOTAL_AMT = fn_sale_total(OLD.SALE_ID)
    WHERE SALE_ID = OLD.SALE_ID;
END $$
DELIMITER ;

INSERT INTO admin VALUES ('admin','admin123'), ('owner','ownerpass');

INSERT INTO suppliers (Sup_Name, Sup_Add, Sup_Phone, Sup_Mail) VALUES
('MedSup Pvt Ltd', 'Bengaluru', '9000000100','sales@medsup.com'),
('Healix Pharmaceuticals', 'Mumbai', '9000000200','contact@healix.in'),
('Sunrise Pharma', 'Chennai', '9000000300','sales@sunrisepharma.com'),
('GlobalMeds Distributors', 'Delhi', '9000000400','orders@globalmeds.com'),
('Apex Healthcare', 'Hyderabad', '9000000500','support@apexhealth.com'),
('BioCare Suppliers', 'Kolkata', '9000000600','info@biocare.co');

INSERT INTO meds (Med_Name, Med_Qty, Category, Med_Price, Location_Rack) VALUES
('Dolo 650 MG', 625, 'Tablet', 1.00, 'A1'),
('Panadol Cold & Flu', 90, 'Tablet', 2.50, 'A1'),
('Livogen', 25, 'Capsule', 5.00, 'B2'),
('Gelusil', 440, 'Tablet', 1.25, 'A3'),
('Cyclopam', 93, 'Tablet', 6.00, 'A2'),
('Paracetamol 500mg', 1200, 'Tablet', 0.75, 'A1'),
('Amoxicillin 500mg', 350, 'Capsule', 4.50, 'B1'),
('Cefixime 200mg', 150, 'Tablet', 7.00, 'B3'),
('Metformin 500mg', 420, 'Tablet', 3.00, 'C1'),
('Glibenclamide 5mg', 210, 'Tablet', 1.80, 'C1'),
('Omeprazole 20mg', 300, 'Capsule', 6.50, 'A4'),
('Cetirizine 10mg', 780, 'Tablet', 0.90, 'A2'),
('Azithromycin 250mg', 200, 'Tablet', 12.00, 'B2'),
('Vitamin C 500mg', 500, 'Tablet', 0.50, 'D1'),
('Calpol Suspension', 80, 'Syrup', 2.20, 'D2'),
('Diclofenac 50mg', 340, 'Tablet', 2.75, 'A3'),
('Ranitidine 150mg', 160, 'Tablet', 1.20, 'A5'),
('Salbutamol Inhaler', 60, 'Inhaler', 120.00, 'E1'),
('Cetaphil Moisturizer', 40, 'Topical', 250.00, 'F1'),
('Insulin Human 100IU/ml', 30, 'Injection', 550.00, 'G1');

INSERT INTO customer VALUES
(200001, 'Walkin', 'Customer', 30, 'F', '9000000001', 'walkin@local'),
(200002, 'Ravi', 'Kumar', 35, 'M', '9000000003', 'ravi.k@example.com'),
(200003, 'Meera', 'Shah', 28, 'F', '9000000004', 'meera.shah@gmail.com'),
(200004, 'Amit', 'Singh', 42, 'M', '9000000005', 'amit.s@mail.com'),
(200005, 'Sita', 'Devi', 50, 'F', '9000000006', 'sita.devi@mail.com'),
(200006, 'Walkin2', 'Guest', 22, 'M', '9000000007', 'guest2@local');

INSERT INTO employee (E_Fname, E_Lname, E_Bdate, E_Age, E_Sex, E_Type, E_Date, E_Add, E_Mail, E_Phone, E_Sal) VALUES
('S','Admin', '2000-01-01', 25, 'F', 'Pharmacist', CURDATE(), 'Store Address','s@store.com','9000000002',15000),
('K','Manager', '1990-05-12', 35, 'M', 'Manager', CURDATE(), 'Main Branch','k.manager@store.com','9000000010',30000),
('N','Assistant', '1998-03-20', 27, 'F', 'Assistant', CURDATE(), 'Main Branch','n.assist@store.com','9000000020',12000);

INSERT INTO emplogin VALUES
('s_admin','s_pass',1),
('k_manager','k_pass',2),
('n_assist','n_pass',3);

INSERT INTO purchase (Med_ID, Sup_ID, P_Qty, P_Cost, P_Date, Mfg_Date, Exp_Date) VALUES
(1, 1, 500, 400.00, '2025-06-01', '2025-05-01', '2027-05-01'),
(2, 2, 200, 350.00, '2025-07-10', '2025-06-15', '2026-12-15'),
(3, 3, 100, 450.00, '2025-08-05', '2025-07-01', '2026-07-01'),
(4, 1, 600, 700.00, '2025-04-20', '2025-03-18', '2027-03-18'),
(5, 4, 200, 1200.00, '2025-09-08', '2025-08-10', '2026-08-10'),
(6, 2, 1000, 500.00, '2025-01-12', '2024-12-01', '2026-12-01'),
(7, 3, 400, 1600.00, '2025-02-15', '2025-01-10', '2026-01-10'),
(8, 4, 180, 900.00, '2025-03-22', '2025-02-01', '2026-02-01'),
(9, 5, 300, 900.00, '2025-05-30', '2025-04-15', '2026-04-15'),
(10, 5, 220, 200.00, '2025-06-14', '2025-05-01', '2027-05-01'),
(11, 6, 250, 1625.00, '2025-08-28', '2025-07-01', '2026-07-01'),
(12, 1, 800, 720.00, '2025-09-30', '2025-08-10', '2026-08-10'),
(13, 2, 150, 1800.00, '2025-10-01', '2025-09-01', '2026-09-01'),
(14, 3, 600, 300.00, '2025-01-18', '2024-12-15', '2026-12-15'),
(15, 4, 120, 264.00, '2025-07-21', '2025-06-10', '2026-06-10'),
(16, 2, 340, 935.00, '2025-03-05', '2025-02-02', '2026-02-02'),
(17, 6, 180, 216.00, '2025-04-10', '2025-03-01', '2026-03-01'),
(18, 1, 75, 9000.00, '2025-09-11', '2025-08-01', '2026-08-01'),
(19, 5, 50, 12500.00, '2025-03-03', '2025-02-01', '2026-02-01'),
(20, 3, 40, 22000.00, '2025-06-06', '2025-05-01', '2026-05-01'),
(5, NULL, 50, 300.00, '2025-11-01', '2025-10-01', '2026-10-01');

INSERT INTO sales (C_ID, E_ID) VALUES
(200001,1),
(200002,2),
(200003,3),
(200004,2),
(200005,1),
(200006,3),
(200002,1);

INSERT INTO sales_items (SALE_ID, MED_ID, SALE_QTY) VALUES
(1, 1, 2),
(1, 12, 3),
(1, 14, 1),
(2, 6, 4),
(2, 11, 1),
(3, 7, 2),
(3, 13, 1),
(3, 2, 1),
(4, 18, 1),
(4, 9, 2),
(5, 19, 1),
(5, 20, 1),
(5, 3, 2),
(6, 4, 5),
(6, 16, 2),
(7, 10, 3),
(7, 15, 2),
(7, 12, 1);

SELECT 'pharmacy schema ready' AS status;
