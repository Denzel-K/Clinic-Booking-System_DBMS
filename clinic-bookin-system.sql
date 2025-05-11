-- Clinic Booking System Database
-- Author: [Denzel Kariuki Ndegwa]

-- Database creation
DROP DATABASE IF EXISTS clinic_booking_system;
CREATE DATABASE clinic_booking_system;
USE clinic_booking_system;

-- Table: patients - Stores patient information
CREATE TABLE patients (
    patient_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender ENUM('Male', 'Female', 'Other') NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100) UNIQUE,
    address VARCHAR(200),
    city VARCHAR(50),
    postal_code VARCHAR(20),
    registration_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_email CHECK (email LIKE '%@%.%')
) COMMENT 'Stores patient demographic information';

-- Table: doctors - Stores doctor information
CREATE TABLE doctors (
    doctor_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    specialization VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    license_number VARCHAR(50) UNIQUE NOT NULL,
    hire_date DATE NOT NULL,
    active BOOLEAN DEFAULT TRUE,
    CONSTRAINT chk_doctor_email CHECK (email LIKE '%@%.%')
) COMMENT 'Stores doctor information and specialties';

-- Table: staff - Stores non-doctor staff information
CREATE TABLE staff (
    staff_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    role VARCHAR(50) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    hire_date DATE NOT NULL,
    active BOOLEAN DEFAULT TRUE
) COMMENT 'Stores information for administrative and support staff';

-- Table: departments - Clinic departments
CREATE TABLE departments (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL UNIQUE,
    location VARCHAR(100) NOT NULL,
    head_doctor_id INT,
    FOREIGN KEY (head_doctor_id) REFERENCES doctors(doctor_id)
) COMMENT 'Clinic departments and their locations';

-- Table: doctor_departments - Many-to-many relationship between doctors and departments
CREATE TABLE doctor_departments (
    doctor_id INT NOT NULL,
    department_id INT NOT NULL,
    PRIMARY KEY (doctor_id, department_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id),
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
) COMMENT 'Tracks which doctors work in which departments';

-- Table: appointment_types - Types of appointments
CREATE TABLE appointment_types (
    type_id INT AUTO_INCREMENT PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL UNIQUE,
    duration_minutes INT NOT NULL,
    description TEXT,
    base_price DECIMAL(10,2) NOT NULL
) COMMENT 'Different types of appointments with durations and prices';

-- Table: doctor_specializations - What appointment types each doctor can handle
CREATE TABLE doctor_specializations (
    doctor_id INT NOT NULL,
    type_id INT NOT NULL,
    PRIMARY KEY (doctor_id, type_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id),
    FOREIGN KEY (type_id) REFERENCES appointment_types(type_id)
) COMMENT 'Tracks which doctors can perform which appointment types';

-- Table: appointments - Main appointment tracking
CREATE TABLE appointments (
    appointment_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    type_id INT NOT NULL,
    scheduled_datetime DATETIME NOT NULL,
    end_datetime DATETIME NOT NULL,
    status ENUM('Scheduled', 'Completed', 'Cancelled', 'No-Show') DEFAULT 'Scheduled',
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by INT NOT NULL,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id),
    FOREIGN KEY (type_id) REFERENCES appointment_types(type_id),
    FOREIGN KEY (created_by) REFERENCES staff(staff_id),
    CONSTRAINT chk_appointment_time CHECK (end_datetime > scheduled_datetime),
    INDEX idx_appointment_datetime (scheduled_datetime)
) COMMENT 'Main table tracking all appointments in the system';

-- Table: medical_records - Patient medical history
CREATE TABLE medical_records (
    record_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_id INT,
    record_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    diagnosis TEXT,
    treatment TEXT,
    prescription TEXT,
    notes TEXT,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id),
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
) COMMENT 'Stores patient medical records and history';

-- Table: invoices - Billing information
CREATE TABLE invoices (
    invoice_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT,
    patient_id INT NOT NULL,
    issue_date DATE NOT NULL,
    due_date DATE NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    paid_amount DECIMAL(10,2) DEFAULT 0,
    status ENUM('Pending', 'Paid', 'Cancelled') DEFAULT 'Pending',
    payment_method VARCHAR(50),
    payment_date DATETIME,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id),
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    CONSTRAINT chk_invoice_dates CHECK (due_date >= issue_date)
) COMMENT 'Tracks patient billing and payments';

-- Table: invoice_items - Line items for invoices
CREATE TABLE invoice_items (
    item_id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_id INT NOT NULL,
    description VARCHAR(200) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    discount DECIMAL(10,2) DEFAULT 0,
    FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id),
    CONSTRAINT chk_positive_quantity CHECK (quantity > 0)
) COMMENT 'Detailed line items for each invoice';

-- Table: clinic_settings - System configuration
CREATE TABLE clinic_settings (
    setting_id INT AUTO_INCREMENT PRIMARY KEY,
    setting_name VARCHAR(100) NOT NULL UNIQUE,
    setting_value TEXT NOT NULL,
    description TEXT,
    last_updated DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) COMMENT 'Stores system configuration settings';

-- Insert initial configuration
INSERT INTO clinic_settings (setting_name, setting_value, description) VALUES
('clinic_name', 'City Health Clinic', 'Name of the clinic'),
('business_hours_start', '08:00:00', 'Opening time'),
('business_hours_end', '17:00:00', 'Closing time'),
('appointment_buffer', '15', 'Minutes between appointments'),
('cancellation_policy', '24', 'Hours notice required for cancellation');

-- Create a view for today's appointments
CREATE VIEW todays_appointments AS
SELECT 
    a.appointment_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    at.type_name AS appointment_type,
    a.scheduled_datetime,
    a.status
FROM 
    appointments a
JOIN 
    patients p ON a.patient_id = p.patient_id
JOIN 
    doctors d ON a.doctor_id = d.doctor_id
JOIN 
    appointment_types at ON a.type_id = at.type_id
WHERE 
    DATE(a.scheduled_datetime) = CURDATE()
ORDER BY 
    a.scheduled_datetime;

-- Create a view for available appointment slots
CREATE VIEW available_slots AS
SELECT 
    d.doctor_id,
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    at.type_id,
    at.type_name,
    at.duration_minutes,
    DATE_ADD(
        CURRENT_DATE(), 
        INTERVAL (FLOOR(TIME_TO_SEC(CURRENT_TIME()) / (15 * 60)) * 15 * 60) SECOND
    ) AS next_slot_start,
    DATE_ADD(
        DATE_ADD(
            CURRENT_DATE(), 
            INTERVAL (FLOOR(TIME_TO_SEC(CURRENT_TIME()) / (15 * 60)) * 15 * 60) SECOND
        ),
        INTERVAL at.duration_minutes MINUTE
    ) AS next_slot_end
FROM 
    doctors d
JOIN 
    doctor_specializations ds ON d.doctor_id = ds.doctor_id
JOIN 
    appointment_types at ON ds.type_id = at.type_id
WHERE 
    d.active = TRUE
    AND NOT EXISTS (
        SELECT 1 FROM appointments a
        WHERE a.doctor_id = d.doctor_id
        AND a.status = 'Scheduled'
        AND (
            (a.scheduled_datetime BETWEEN next_slot_start AND next_slot_end)
            OR (a.end_datetime BETWEEN next_slot_start AND next_slot_end)
            OR (next_slot_start BETWEEN a.scheduled_datetime AND a.end_datetime)
        )
    );