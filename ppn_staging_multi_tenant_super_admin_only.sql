-- MariaDB dump 10.19  Distrib 10.4.32-MariaDB, for Win64 (AMD64)
--
-- Host: localhost    Database: ppn_clean_multi_tenant
-- ------------------------------------------------------
-- Server version	10.4.32-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `activity_logs`
--

DROP TABLE IF EXISTS `activity_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `activity_logs` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `branch_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `user_id` bigint(20) unsigned DEFAULT NULL,
  `project_id` bigint(20) unsigned DEFAULT NULL,
  `action` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `entity_type` varchar(50) DEFAULT NULL,
  `entity_id` bigint(20) unsigned DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `activity_logs_user_id_foreign` (`user_id`),
  KEY `activity_logs_project_id_foreign` (`project_id`),
  KEY `activity_logs_shop_id_branch_id_index` (`shop_id`,`branch_id`),
  CONSTRAINT `activity_logs_project_id_foreign` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE SET NULL,
  CONSTRAINT `activity_logs_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `activity_logs`
--

LOCK TABLES `activity_logs` WRITE;
/*!40000 ALTER TABLE `activity_logs` DISABLE KEYS */;
/*!40000 ALTER TABLE `activity_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `additional_requests`
--

DROP TABLE IF EXISTS `additional_requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `additional_requests` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `project_id` bigint(20) unsigned NOT NULL,
  `description` text NOT NULL,
  `cost` decimal(12,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `additional_requests_project_id_foreign` (`project_id`),
  CONSTRAINT `additional_requests_project_id_foreign` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `additional_requests`
--

LOCK TABLES `additional_requests` WRITE;
/*!40000 ALTER TABLE `additional_requests` DISABLE KEYS */;
/*!40000 ALTER TABLE `additional_requests` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `artwork_logs`
--

DROP TABLE IF EXISTS `artwork_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `artwork_logs` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `branch_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `project_id` bigint(20) unsigned NOT NULL,
  `product_item_id` bigint(20) unsigned DEFAULT NULL,
  `artwork_code` varchar(20) NOT NULL,
  `attempt` tinyint(3) unsigned NOT NULL DEFAULT 1,
  `version` varchar(50) NOT NULL,
  `source` enum('In-house Designer','Freelance','Customer Provided','Supplier') NOT NULL DEFAULT 'In-house Designer',
  `status` enum('Awaiting Approval','Reviewing','Need Revision','Rejected','Approved by Client','Approved by Supplier') NOT NULL DEFAULT 'Awaiting Approval',
  `file_name` varchar(255) DEFAULT NULL,
  `file_path` varchar(500) DEFAULT NULL,
  `feedback` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `artwork_logs_project_id_foreign` (`project_id`),
  KEY `artwork_logs_product_item_id_foreign` (`product_item_id`),
  KEY `artwork_logs_status_index` (`status`),
  KEY `artwork_logs_shop_id_branch_id_index` (`shop_id`,`branch_id`),
  CONSTRAINT `artwork_logs_product_item_id_foreign` FOREIGN KEY (`product_item_id`) REFERENCES `product_items` (`id`) ON DELETE SET NULL,
  CONSTRAINT `artwork_logs_project_id_foreign` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `artwork_logs`
--

LOCK TABLES `artwork_logs` WRITE;
/*!40000 ALTER TABLE `artwork_logs` DISABLE KEYS */;
/*!40000 ALTER TABLE `artwork_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `branches`
--

DROP TABLE IF EXISTS `branches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `branches` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint(20) unsigned NOT NULL,
  `code` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `address` text DEFAULT NULL,
  `phone` varchar(255) DEFAULT NULL,
  `status` enum('active','inactive') NOT NULL DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `branches_shop_id_code_unique` (`shop_id`,`code`),
  CONSTRAINT `branches_shop_id_foreign` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `branches`
--

LOCK TABLES `branches` WRITE;
/*!40000 ALTER TABLE `branches` DISABLE KEYS */;
INSERT INTO `branches` VALUES (1,1,'HQ-BANGKOK','สำนักงานใหญ่ (HQ)',NULL,NULL,'active','2026-07-26 19:12:57','2026-07-26 19:12:57');
/*!40000 ALTER TABLE `branches` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cache`
--

DROP TABLE IF EXISTS `cache`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cache` (
  `key` varchar(255) NOT NULL,
  `value` mediumtext NOT NULL,
  `expiration` int(11) NOT NULL,
  PRIMARY KEY (`key`),
  KEY `cache_expiration_index` (`expiration`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cache`
--

LOCK TABLES `cache` WRITE;
/*!40000 ALTER TABLE `cache` DISABLE KEYS */;
/*!40000 ALTER TABLE `cache` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cache_locks`
--

DROP TABLE IF EXISTS `cache_locks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cache_locks` (
  `key` varchar(255) NOT NULL,
  `owner` varchar(255) NOT NULL,
  `expiration` int(11) NOT NULL,
  PRIMARY KEY (`key`),
  KEY `cache_locks_expiration_index` (`expiration`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cache_locks`
--

LOCK TABLES `cache_locks` WRITE;
/*!40000 ALTER TABLE `cache_locks` DISABLE KEYS */;
/*!40000 ALTER TABLE `cache_locks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `client_samples`
--

DROP TABLE IF EXISTS `client_samples`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `client_samples` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `branch_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `project_id` bigint(20) unsigned NOT NULL,
  `product_item_id` bigint(20) unsigned DEFAULT NULL,
  `sample_code` varchar(20) NOT NULL,
  `attempt` tinyint(3) unsigned NOT NULL DEFAULT 1,
  `sample_type` enum('Pre-production Sample','Material Swatch','3D Printed Mockup','Other') NOT NULL DEFAULT 'Pre-production Sample',
  `origin` enum('China','In-Stock') NOT NULL DEFAULT 'China',
  `supplier_name` varchar(255) DEFAULT NULL,
  `status` enum('Waiting from China','Received from China','Sent to Client','Delivered to Client','Approved','Rejected') NOT NULL DEFAULT 'Waiting from China',
  `sent_date` date DEFAULT NULL,
  `china_tracking` varchar(100) DEFAULT NULL,
  `local_courier` varchar(100) DEFAULT NULL,
  `local_tracking` varchar(100) DEFAULT NULL,
  `feedback` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `client_samples_project_id_foreign` (`project_id`),
  KEY `client_samples_product_item_id_foreign` (`product_item_id`),
  KEY `client_samples_status_index` (`status`),
  KEY `client_samples_shop_id_branch_id_index` (`shop_id`,`branch_id`),
  CONSTRAINT `client_samples_product_item_id_foreign` FOREIGN KEY (`product_item_id`) REFERENCES `product_items` (`id`) ON DELETE SET NULL,
  CONSTRAINT `client_samples_project_id_foreign` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `client_samples`
--

LOCK TABLES `client_samples` WRITE;
/*!40000 ALTER TABLE `client_samples` DISABLE KEYS */;
/*!40000 ALTER TABLE `client_samples` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `contact_persons`
--

DROP TABLE IF EXISTS `contact_persons`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `contact_persons` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `customer_id` bigint(20) unsigned NOT NULL,
  `name` varchar(255) NOT NULL,
  `role` varchar(100) DEFAULT NULL,
  `phone` varchar(50) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `line_id` varchar(100) DEFAULT NULL,
  `other_chat` varchar(255) DEFAULT NULL,
  `is_primary` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `contact_persons_customer_id_foreign` (`customer_id`),
  CONSTRAINT `contact_persons_customer_id_foreign` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `contact_persons`
--

LOCK TABLES `contact_persons` WRITE;
/*!40000 ALTER TABLE `contact_persons` DISABLE KEYS */;
/*!40000 ALTER TABLE `contact_persons` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `container_projects`
--

DROP TABLE IF EXISTS `container_projects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `container_projects` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `container_id` bigint(20) unsigned NOT NULL,
  `project_id` bigint(20) unsigned NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `container_projects_container_id_project_id_unique` (`container_id`,`project_id`),
  KEY `container_projects_project_id_foreign` (`project_id`),
  CONSTRAINT `container_projects_container_id_foreign` FOREIGN KEY (`container_id`) REFERENCES `containers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `container_projects_project_id_foreign` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `container_projects`
--

LOCK TABLES `container_projects` WRITE;
/*!40000 ALTER TABLE `container_projects` DISABLE KEYS */;
/*!40000 ALTER TABLE `container_projects` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `containers`
--

DROP TABLE IF EXISTS `containers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `containers` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `branch_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `container_code` varchar(30) NOT NULL,
  `container_no` varchar(255) DEFAULT NULL,
  `vessel_name` varchar(255) DEFAULT NULL,
  `port_origin` varchar(255) DEFAULT NULL,
  `port_destination` varchar(255) DEFAULT NULL,
  `status` enum('Factory to Port','Sailing','Port to Warehouse','Delivered') NOT NULL DEFAULT 'Factory to Port',
  `factory_departure` date DEFAULT NULL,
  `domestic_tracking` varchar(100) DEFAULT NULL,
  `port_arrival_china` date DEFAULT NULL,
  `etd` date DEFAULT NULL,
  `eta` date DEFAULT NULL,
  `actual_arrival` date DEFAULT NULL,
  `customs_cleared` tinyint(1) NOT NULL DEFAULT 0,
  `customs_date` date DEFAULT NULL,
  `warehouse_arrival` date DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `containers_container_code_unique` (`container_code`),
  KEY `containers_status_index` (`status`),
  KEY `containers_shop_id_branch_id_index` (`shop_id`,`branch_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `containers`
--

LOCK TABLES `containers` WRITE;
/*!40000 ALTER TABLE `containers` DISABLE KEYS */;
/*!40000 ALTER TABLE `containers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `customers`
--

DROP TABLE IF EXISTS `customers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `customers` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `name` varchar(255) NOT NULL,
  `type` enum('Enterprise','Mid-Market','SME') NOT NULL DEFAULT 'SME',
  `status` enum('Active','Inactive') NOT NULL DEFAULT 'Active',
  `tax_id` varchar(20) DEFAULT NULL,
  `branch` varchar(100) DEFAULT NULL,
  `industry` varchar(100) DEFAULT NULL,
  `lead_source` enum('Facebook Ads','Google Search','Referral','Exhibition','Direct Contact','Other') DEFAULT NULL,
  `internal_note` text DEFAULT NULL,
  `billing_address` text DEFAULT NULL,
  `created_by` bigint(20) unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `customers_created_by_foreign` (`created_by`),
  KEY `customers_status_index` (`status`),
  KEY `customers_type_index` (`type`),
  KEY `customers_shop_id_index` (`shop_id`),
  CONSTRAINT `customers_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `customers`
--

LOCK TABLES `customers` WRITE;
/*!40000 ALTER TABLE `customers` DISABLE KEYS */;
/*!40000 ALTER TABLE `customers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `delivery_items`
--

DROP TABLE IF EXISTS `delivery_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `delivery_items` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `branch_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `dispatch_round_id` bigint(20) unsigned NOT NULL,
  `project_id` bigint(20) unsigned NOT NULL,
  `product_item_id` bigint(20) unsigned DEFAULT NULL,
  `customer_name` varchar(255) DEFAULT NULL,
  `delivery_address` text DEFAULT NULL,
  `qty_to_deliver` int(10) unsigned NOT NULL DEFAULT 0,
  `warehouse_id` bigint(20) unsigned DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `delivery_items_dispatch_round_id_foreign` (`dispatch_round_id`),
  KEY `delivery_items_project_id_foreign` (`project_id`),
  KEY `delivery_items_product_item_id_foreign` (`product_item_id`),
  KEY `delivery_items_warehouse_id_foreign` (`warehouse_id`),
  KEY `delivery_items_shop_id_branch_id_index` (`shop_id`,`branch_id`),
  CONSTRAINT `delivery_items_dispatch_round_id_foreign` FOREIGN KEY (`dispatch_round_id`) REFERENCES `dispatch_rounds` (`id`) ON DELETE CASCADE,
  CONSTRAINT `delivery_items_product_item_id_foreign` FOREIGN KEY (`product_item_id`) REFERENCES `product_items` (`id`) ON DELETE SET NULL,
  CONSTRAINT `delivery_items_project_id_foreign` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`),
  CONSTRAINT `delivery_items_warehouse_id_foreign` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `delivery_items`
--

LOCK TABLES `delivery_items` WRITE;
/*!40000 ALTER TABLE `delivery_items` DISABLE KEYS */;
/*!40000 ALTER TABLE `delivery_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dispatch_rounds`
--

DROP TABLE IF EXISTS `dispatch_rounds`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `dispatch_rounds` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `branch_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `dispatch_code` varchar(20) NOT NULL,
  `dispatch_date` date NOT NULL,
  `driver_name` varchar(255) DEFAULT NULL,
  `vehicle_plate` varchar(50) DEFAULT NULL,
  `status` enum('Scheduled','In Transit','Delivered') NOT NULL DEFAULT 'Scheduled',
  `notes` text DEFAULT NULL,
  `created_by` bigint(20) unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `dispatch_rounds_dispatch_code_unique` (`dispatch_code`),
  KEY `dispatch_rounds_created_by_foreign` (`created_by`),
  KEY `dispatch_rounds_status_index` (`status`),
  KEY `dispatch_rounds_shop_id_branch_id_index` (`shop_id`,`branch_id`),
  CONSTRAINT `dispatch_rounds_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dispatch_rounds`
--

LOCK TABLES `dispatch_rounds` WRITE;
/*!40000 ALTER TABLE `dispatch_rounds` DISABLE KEYS */;
/*!40000 ALTER TABLE `dispatch_rounds` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `failed_jobs`
--

DROP TABLE IF EXISTS `failed_jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `failed_jobs` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varchar(255) NOT NULL,
  `connection` text NOT NULL,
  `queue` text NOT NULL,
  `payload` longtext NOT NULL,
  `exception` longtext NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `failed_jobs`
--

LOCK TABLES `failed_jobs` WRITE;
/*!40000 ALTER TABLE `failed_jobs` DISABLE KEYS */;
/*!40000 ALTER TABLE `failed_jobs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `finance_doc_items`
--

DROP TABLE IF EXISTS `finance_doc_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `finance_doc_items` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `finance_document_id` bigint(20) unsigned NOT NULL,
  `item_name` varchar(255) NOT NULL,
  `qty` int(10) unsigned NOT NULL DEFAULT 1,
  `unit_price` decimal(12,2) NOT NULL DEFAULT 0.00,
  `total_price` decimal(14,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `finance_doc_items_finance_document_id_foreign` (`finance_document_id`),
  CONSTRAINT `finance_doc_items_finance_document_id_foreign` FOREIGN KEY (`finance_document_id`) REFERENCES `finance_documents` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `finance_doc_items`
--

LOCK TABLES `finance_doc_items` WRITE;
/*!40000 ALTER TABLE `finance_doc_items` DISABLE KEYS */;
/*!40000 ALTER TABLE `finance_doc_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `finance_documents`
--

DROP TABLE IF EXISTS `finance_documents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `finance_documents` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `branch_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `doc_no` varchar(30) NOT NULL,
  `project_id` bigint(20) unsigned NOT NULL,
  `customer_id` bigint(20) unsigned NOT NULL,
  `doc_type` enum('QU','PI','DP','CI') NOT NULL,
  `status` enum('Draft','Sent','Paid','Overdue','Cancelled') NOT NULL DEFAULT 'Draft',
  `total_amount` decimal(14,2) NOT NULL DEFAULT 0.00,
  `credit_term` varchar(50) DEFAULT NULL,
  `issue_date` date DEFAULT NULL,
  `due_date` date DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_by` bigint(20) unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `finance_documents_doc_no_unique` (`doc_no`),
  KEY `finance_documents_customer_id_foreign` (`customer_id`),
  KEY `finance_documents_created_by_foreign` (`created_by`),
  KEY `finance_documents_status_index` (`status`),
  KEY `finance_documents_project_id_doc_type_index` (`project_id`,`doc_type`),
  KEY `finance_documents_shop_id_branch_id_index` (`shop_id`,`branch_id`),
  CONSTRAINT `finance_documents_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `finance_documents_customer_id_foreign` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`),
  CONSTRAINT `finance_documents_project_id_foreign` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `finance_documents`
--

LOCK TABLES `finance_documents` WRITE;
/*!40000 ALTER TABLE `finance_documents` DISABLE KEYS */;
/*!40000 ALTER TABLE `finance_documents` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `job_batches`
--

DROP TABLE IF EXISTS `job_batches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `job_batches` (
  `id` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `total_jobs` int(11) NOT NULL,
  `pending_jobs` int(11) NOT NULL,
  `failed_jobs` int(11) NOT NULL,
  `failed_job_ids` longtext NOT NULL,
  `options` mediumtext DEFAULT NULL,
  `cancelled_at` int(11) DEFAULT NULL,
  `created_at` int(11) NOT NULL,
  `finished_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `job_batches`
--

LOCK TABLES `job_batches` WRITE;
/*!40000 ALTER TABLE `job_batches` DISABLE KEYS */;
/*!40000 ALTER TABLE `job_batches` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jobs`
--

DROP TABLE IF EXISTS `jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `jobs` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `queue` varchar(255) NOT NULL,
  `payload` longtext NOT NULL,
  `attempts` tinyint(3) unsigned NOT NULL,
  `reserved_at` int(10) unsigned DEFAULT NULL,
  `available_at` int(10) unsigned NOT NULL,
  `created_at` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `jobs_queue_index` (`queue`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jobs`
--

LOCK TABLES `jobs` WRITE;
/*!40000 ALTER TABLE `jobs` DISABLE KEYS */;
/*!40000 ALTER TABLE `jobs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `migrations`
--

DROP TABLE IF EXISTS `migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `migrations` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `migration` varchar(255) NOT NULL,
  `batch` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `migrations`
--

LOCK TABLES `migrations` WRITE;
/*!40000 ALTER TABLE `migrations` DISABLE KEYS */;
INSERT INTO `migrations` VALUES (1,'0001_01_01_000000_create_users_table',1),(2,'0001_01_01_000001_create_cache_table',1),(3,'0001_01_01_000002_create_jobs_table',1),(4,'2026_07_04_000001_create_customers_and_contacts_tables',1),(5,'2026_07_04_000002_create_projects_and_products_tables',1),(6,'2026_07_04_000003_create_suppliers_and_procurement_tables',1),(7,'2026_07_04_000004_create_samples_and_artwork_tables',1),(8,'2026_07_04_000005_create_finance_and_payments_tables',1),(9,'2026_07_04_000006_create_logistics_and_inventory_tables',1),(10,'2026_07_04_000007_create_activity_logs_table',1),(11,'2026_07_15_141935_add_po_file_to_projects_table',1),(12,'2026_07_15_141947_add_po_file_to_projects_table',1),(13,'2026_07_15_160234_create_quote_request_revisions_table',1),(14,'2026_07_27_000001_create_shops_and_branches_tables',1),(15,'2026_07_27_000002_add_shop_and_branch_ids_to_existing_tables',1);
/*!40000 ALTER TABLE `migrations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `password_reset_tokens`
--

DROP TABLE IF EXISTS `password_reset_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `password_reset_tokens` (
  `email` varchar(255) NOT NULL,
  `token` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `password_reset_tokens`
--

LOCK TABLES `password_reset_tokens` WRITE;
/*!40000 ALTER TABLE `password_reset_tokens` DISABLE KEYS */;
/*!40000 ALTER TABLE `password_reset_tokens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `payments`
--

DROP TABLE IF EXISTS `payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `payments` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `branch_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `project_id` bigint(20) unsigned NOT NULL,
  `finance_document_id` bigint(20) unsigned DEFAULT NULL,
  `customer_id` bigint(20) unsigned NOT NULL,
  `payment_type` enum('Deposit','Balance','Full') NOT NULL,
  `amount` decimal(14,2) NOT NULL,
  `method` enum('Bank Transfer','Cheque','Cash','Other') NOT NULL DEFAULT 'Bank Transfer',
  `payment_date` date NOT NULL,
  `status` enum('Pending Verification','Confirmed') NOT NULL DEFAULT 'Pending Verification',
  `slip_file_path` varchar(500) DEFAULT NULL,
  `verified_by` bigint(20) unsigned DEFAULT NULL,
  `verified_at` timestamp NULL DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `payments_project_id_foreign` (`project_id`),
  KEY `payments_finance_document_id_foreign` (`finance_document_id`),
  KEY `payments_customer_id_foreign` (`customer_id`),
  KEY `payments_verified_by_foreign` (`verified_by`),
  KEY `payments_status_index` (`status`),
  KEY `payments_shop_id_branch_id_index` (`shop_id`,`branch_id`),
  CONSTRAINT `payments_customer_id_foreign` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`),
  CONSTRAINT `payments_finance_document_id_foreign` FOREIGN KEY (`finance_document_id`) REFERENCES `finance_documents` (`id`) ON DELETE SET NULL,
  CONSTRAINT `payments_project_id_foreign` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`),
  CONSTRAINT `payments_verified_by_foreign` FOREIGN KEY (`verified_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `payments`
--

LOCK TABLES `payments` WRITE;
/*!40000 ALTER TABLE `payments` DISABLE KEYS */;
/*!40000 ALTER TABLE `payments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `product_files`
--

DROP TABLE IF EXISTS `product_files`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `product_files` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `product_item_id` bigint(20) unsigned NOT NULL,
  `file_type` enum('reference','artwork') NOT NULL DEFAULT 'reference',
  `file_name` varchar(255) NOT NULL,
  `file_path` varchar(500) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `product_files_product_item_id_foreign` (`product_item_id`),
  CONSTRAINT `product_files_product_item_id_foreign` FOREIGN KEY (`product_item_id`) REFERENCES `product_items` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `product_files`
--

LOCK TABLES `product_files` WRITE;
/*!40000 ALTER TABLE `product_files` DISABLE KEYS */;
/*!40000 ALTER TABLE `product_files` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `product_items`
--

DROP TABLE IF EXISTS `product_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `product_items` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `branch_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `project_id` bigint(20) unsigned NOT NULL,
  `name` varchar(255) NOT NULL,
  `qty` int(10) unsigned NOT NULL DEFAULT 0,
  `specs` text DEFAULT NULL,
  `target_date` date DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `product_items_project_id_foreign` (`project_id`),
  KEY `product_items_shop_id_branch_id_index` (`shop_id`,`branch_id`),
  CONSTRAINT `product_items_project_id_foreign` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `product_items`
--

LOCK TABLES `product_items` WRITE;
/*!40000 ALTER TABLE `product_items` DISABLE KEYS */;
/*!40000 ALTER TABLE `product_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `product_variations`
--

DROP TABLE IF EXISTS `product_variations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `product_variations` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `product_item_id` bigint(20) unsigned NOT NULL,
  `variation_name` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `product_variations_product_item_id_foreign` (`product_item_id`),
  CONSTRAINT `product_variations_product_item_id_foreign` FOREIGN KEY (`product_item_id`) REFERENCES `product_items` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `product_variations`
--

LOCK TABLES `product_variations` WRITE;
/*!40000 ALTER TABLE `product_variations` DISABLE KEYS */;
/*!40000 ALTER TABLE `product_variations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `projects`
--

DROP TABLE IF EXISTS `projects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `projects` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `branch_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `project_code` varchar(20) NOT NULL,
  `customer_id` bigint(20) unsigned NOT NULL,
  `contact_person_id` bigint(20) unsigned DEFAULT NULL,
  `status` enum('Inquiry','Sample','Production','Shipping','Distributing','Delivered','Cancelled') NOT NULL DEFAULT 'Inquiry',
  `step` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `priority` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `is_repeat_order` tinyint(1) NOT NULL DEFAULT 0,
  `target_date` date DEFAULT NULL,
  `order_value` decimal(14,2) NOT NULL DEFAULT 0.00,
  `usage_location` text DEFAULT NULL,
  `credit_term` enum('Advance','15 Days','30 Days','45 Days','60 Days') NOT NULL DEFAULT '30 Days',
  `deposit_paid` tinyint(1) NOT NULL DEFAULT 0,
  `balance_paid` tinyint(1) NOT NULL DEFAULT 0,
  `ocpb_passed` tinyint(1) NOT NULL DEFAULT 0,
  `shipping_mark_ready` tinyint(1) NOT NULL DEFAULT 0,
  `po_file_path` varchar(500) DEFAULT NULL,
  `po_file_name` varchar(255) DEFAULT NULL,
  `created_by` bigint(20) unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `projects_project_code_unique` (`project_code`),
  KEY `projects_contact_person_id_foreign` (`contact_person_id`),
  KEY `projects_created_by_foreign` (`created_by`),
  KEY `projects_status_index` (`status`),
  KEY `projects_customer_id_index` (`customer_id`),
  KEY `projects_shop_id_branch_id_index` (`shop_id`,`branch_id`),
  CONSTRAINT `projects_contact_person_id_foreign` FOREIGN KEY (`contact_person_id`) REFERENCES `contact_persons` (`id`) ON DELETE SET NULL,
  CONSTRAINT `projects_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `projects_customer_id_foreign` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `projects`
--

LOCK TABLES `projects` WRITE;
/*!40000 ALTER TABLE `projects` DISABLE KEYS */;
/*!40000 ALTER TABLE `projects` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `quote_request_revisions`
--

DROP TABLE IF EXISTS `quote_request_revisions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `quote_request_revisions` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `quote_request_id` bigint(20) unsigned NOT NULL,
  `actor` varchar(255) NOT NULL,
  `quoted_price` decimal(12,2) DEFAULT NULL,
  `currency` varchar(10) NOT NULL DEFAULT 'USD',
  `lead_time` varchar(100) DEFAULT NULL,
  `moq` int(11) DEFAULT NULL,
  `sample_price` decimal(12,2) NOT NULL DEFAULT 0.00,
  `sample_lead_time` varchar(100) DEFAULT NULL,
  `sample_condition` varchar(100) DEFAULT NULL,
  `remark` text DEFAULT NULL,
  `buyer_note` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `quote_request_revisions_quote_request_id_foreign` (`quote_request_id`),
  CONSTRAINT `quote_request_revisions_quote_request_id_foreign` FOREIGN KEY (`quote_request_id`) REFERENCES `quote_requests` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `quote_request_revisions`
--

LOCK TABLES `quote_request_revisions` WRITE;
/*!40000 ALTER TABLE `quote_request_revisions` DISABLE KEYS */;
/*!40000 ALTER TABLE `quote_request_revisions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `quote_requests`
--

DROP TABLE IF EXISTS `quote_requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `quote_requests` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `branch_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `supplier_id` bigint(20) unsigned NOT NULL,
  `project_id` bigint(20) unsigned NOT NULL,
  `product_item_id` bigint(20) unsigned DEFAULT NULL,
  `customer_name` varchar(255) DEFAULT NULL,
  `product_name` varchar(255) NOT NULL,
  `qty` int(10) unsigned NOT NULL DEFAULT 0,
  `specs` text DEFAULT NULL,
  `variations` text DEFAULT NULL,
  `target_date` date DEFAULT NULL,
  `packing` varchar(255) DEFAULT NULL,
  `status` enum('Waiting Link','Link Sent','Price Filled','Needs Revision','Approved') NOT NULL DEFAULT 'Waiting Link',
  `quoted_price` decimal(12,2) DEFAULT NULL,
  `currency` enum('USD','THB') NOT NULL DEFAULT 'USD',
  `lead_time` varchar(100) DEFAULT NULL,
  `moq` int(10) unsigned DEFAULT NULL,
  `sample_price` decimal(12,2) DEFAULT 0.00,
  `sample_lead_time` varchar(100) DEFAULT NULL,
  `sample_condition` enum('Refundable','Non-Refundable','Free') DEFAULT NULL,
  `buyer_note` text DEFAULT NULL,
  `remark` text DEFAULT NULL,
  `session_token` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `quote_requests_session_token_unique` (`session_token`),
  KEY `quote_requests_supplier_id_foreign` (`supplier_id`),
  KEY `quote_requests_project_id_foreign` (`project_id`),
  KEY `quote_requests_product_item_id_foreign` (`product_item_id`),
  KEY `quote_requests_status_index` (`status`),
  KEY `quote_requests_shop_id_branch_id_index` (`shop_id`,`branch_id`),
  CONSTRAINT `quote_requests_product_item_id_foreign` FOREIGN KEY (`product_item_id`) REFERENCES `product_items` (`id`) ON DELETE SET NULL,
  CONSTRAINT `quote_requests_project_id_foreign` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`),
  CONSTRAINT `quote_requests_supplier_id_foreign` FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `quote_requests`
--

LOCK TABLES `quote_requests` WRITE;
/*!40000 ALTER TABLE `quote_requests` DISABLE KEYS */;
/*!40000 ALTER TABLE `quote_requests` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sessions` (
  `id` varchar(255) NOT NULL,
  `user_id` bigint(20) unsigned DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `payload` longtext NOT NULL,
  `last_activity` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `sessions_user_id_index` (`user_id`),
  KEY `sessions_last_activity_index` (`last_activity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sessions`
--

LOCK TABLES `sessions` WRITE;
/*!40000 ALTER TABLE `sessions` DISABLE KEYS */;
/*!40000 ALTER TABLE `sessions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `shipping_addresses`
--

DROP TABLE IF EXISTS `shipping_addresses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `shipping_addresses` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `customer_id` bigint(20) unsigned NOT NULL,
  `label` varchar(255) NOT NULL,
  `address` text NOT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `shipping_addresses_customer_id_foreign` (`customer_id`),
  CONSTRAINT `shipping_addresses_customer_id_foreign` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shipping_addresses`
--

LOCK TABLES `shipping_addresses` WRITE;
/*!40000 ALTER TABLE `shipping_addresses` DISABLE KEYS */;
/*!40000 ALTER TABLE `shipping_addresses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `shops`
--

DROP TABLE IF EXISTS `shops`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `shops` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `code` varchar(255) DEFAULT NULL,
  `owner_user_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `status` enum('active','suspended','closed') NOT NULL DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `shops_code_unique` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shops`
--

LOCK TABLES `shops` WRITE;
/*!40000 ALTER TABLE `shops` DISABLE KEYS */;
INSERT INTO `shops` VALUES (1,'PPN GREAT Headquarter','HQ001',1,'active','2026-07-26 19:12:57','2026-07-26 19:12:57');
/*!40000 ALTER TABLE `shops` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `stock_items`
--

DROP TABLE IF EXISTS `stock_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `stock_items` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `branch_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `warehouse_id` bigint(20) unsigned NOT NULL,
  `product_item_id` bigint(20) unsigned NOT NULL,
  `project_id` bigint(20) unsigned NOT NULL,
  `qty_in_stock` int(11) NOT NULL DEFAULT 0,
  `qty_reserved` int(11) NOT NULL DEFAULT 0,
  `location_in_warehouse` varchar(100) DEFAULT NULL,
  `last_received_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `stock_items_warehouse_id_foreign` (`warehouse_id`),
  KEY `stock_items_product_item_id_foreign` (`product_item_id`),
  KEY `stock_items_project_id_foreign` (`project_id`),
  KEY `stock_items_shop_id_branch_id_index` (`shop_id`,`branch_id`),
  CONSTRAINT `stock_items_product_item_id_foreign` FOREIGN KEY (`product_item_id`) REFERENCES `product_items` (`id`),
  CONSTRAINT `stock_items_project_id_foreign` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`),
  CONSTRAINT `stock_items_warehouse_id_foreign` FOREIGN KEY (`warehouse_id`) REFERENCES `warehouses` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stock_items`
--

LOCK TABLES `stock_items` WRITE;
/*!40000 ALTER TABLE `stock_items` DISABLE KEYS */;
/*!40000 ALTER TABLE `stock_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `stock_movements`
--

DROP TABLE IF EXISTS `stock_movements`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `stock_movements` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `branch_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `stock_item_id` bigint(20) unsigned NOT NULL,
  `movement_type` enum('IN','OUT','ADJUST') NOT NULL,
  `qty` int(11) NOT NULL,
  `reference_type` varchar(50) DEFAULT NULL,
  `reference_id` bigint(20) unsigned DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_by` bigint(20) unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `stock_movements_stock_item_id_foreign` (`stock_item_id`),
  KEY `stock_movements_created_by_foreign` (`created_by`),
  KEY `stock_movements_movement_type_index` (`movement_type`),
  KEY `stock_movements_shop_id_branch_id_index` (`shop_id`,`branch_id`),
  CONSTRAINT `stock_movements_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `stock_movements_stock_item_id_foreign` FOREIGN KEY (`stock_item_id`) REFERENCES `stock_items` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stock_movements`
--

LOCK TABLES `stock_movements` WRITE;
/*!40000 ALTER TABLE `stock_movements` DISABLE KEYS */;
/*!40000 ALTER TABLE `stock_movements` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `supplier_bills`
--

DROP TABLE IF EXISTS `supplier_bills`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `supplier_bills` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `branch_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `supplier_id` bigint(20) unsigned NOT NULL,
  `project_id` bigint(20) unsigned NOT NULL,
  `product_name` varchar(255) NOT NULL,
  `bill_type` enum('Deposit','Balance','Full Payment') NOT NULL,
  `amount` decimal(14,2) NOT NULL DEFAULT 0.00,
  `currency` enum('USD','THB') NOT NULL DEFAULT 'USD',
  `due_month` varchar(20) DEFAULT NULL,
  `status` enum('Pending','Paid','Overdue') NOT NULL DEFAULT 'Pending',
  `pi_uploaded` tinyint(1) NOT NULL DEFAULT 0,
  `pi_file_path` varchar(500) DEFAULT NULL,
  `invoice_uploaded` tinyint(1) NOT NULL DEFAULT 0,
  `invoice_file_path` varchar(500) DEFAULT NULL,
  `paid_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `supplier_bills_supplier_id_foreign` (`supplier_id`),
  KEY `supplier_bills_project_id_foreign` (`project_id`),
  KEY `supplier_bills_status_index` (`status`),
  KEY `supplier_bills_shop_id_branch_id_index` (`shop_id`,`branch_id`),
  CONSTRAINT `supplier_bills_project_id_foreign` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`),
  CONSTRAINT `supplier_bills_supplier_id_foreign` FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `supplier_bills`
--

LOCK TABLES `supplier_bills` WRITE;
/*!40000 ALTER TABLE `supplier_bills` DISABLE KEYS */;
/*!40000 ALTER TABLE `supplier_bills` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `supplier_samples`
--

DROP TABLE IF EXISTS `supplier_samples`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `supplier_samples` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `branch_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `supplier_id` bigint(20) unsigned NOT NULL,
  `project_id` bigint(20) unsigned NOT NULL,
  `product_name` varchar(255) NOT NULL,
  `customer_name` varchar(255) DEFAULT NULL,
  `status` enum('Waiting Supplier','Sample Sent','Approved') NOT NULL DEFAULT 'Waiting Supplier',
  `specs` text DEFAULT NULL,
  `cost` varchar(50) NOT NULL DEFAULT 'TBD',
  `tracking_no` varchar(100) DEFAULT NULL,
  `expected_date` date DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `supplier_samples_supplier_id_foreign` (`supplier_id`),
  KEY `supplier_samples_project_id_foreign` (`project_id`),
  KEY `supplier_samples_status_index` (`status`),
  KEY `supplier_samples_shop_id_branch_id_index` (`shop_id`,`branch_id`),
  CONSTRAINT `supplier_samples_project_id_foreign` FOREIGN KEY (`project_id`) REFERENCES `projects` (`id`),
  CONSTRAINT `supplier_samples_supplier_id_foreign` FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `supplier_samples`
--

LOCK TABLES `supplier_samples` WRITE;
/*!40000 ALTER TABLE `supplier_samples` DISABLE KEYS */;
/*!40000 ALTER TABLE `supplier_samples` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `suppliers`
--

DROP TABLE IF EXISTS `suppliers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `suppliers` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `name` varchar(255) NOT NULL,
  `category` varchar(100) DEFAULT NULL,
  `contact_person` varchar(255) DEFAULT NULL,
  `phone` varchar(100) DEFAULT NULL,
  `wechat` varchar(100) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `rating` decimal(2,1) NOT NULL DEFAULT 0.0,
  `notes` text DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `suppliers_shop_id_index` (`shop_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `suppliers`
--

LOCK TABLES `suppliers` WRITE;
/*!40000 ALTER TABLE `suppliers` DISABLE KEYS */;
/*!40000 ALTER TABLE `suppliers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_branch_permissions`
--

DROP TABLE IF EXISTS `user_branch_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_branch_permissions` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) unsigned NOT NULL,
  `shop_id` bigint(20) unsigned NOT NULL,
  `branch_id` bigint(20) unsigned NOT NULL,
  `role` enum('branch_manager','sales','purchasing','finance','warehouse','employee') NOT NULL DEFAULT 'branch_manager',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_branch_permissions_user_id_branch_id_unique` (`user_id`,`branch_id`),
  KEY `user_branch_permissions_shop_id_foreign` (`shop_id`),
  KEY `user_branch_permissions_branch_id_foreign` (`branch_id`),
  CONSTRAINT `user_branch_permissions_branch_id_foreign` FOREIGN KEY (`branch_id`) REFERENCES `branches` (`id`) ON DELETE CASCADE,
  CONSTRAINT `user_branch_permissions_shop_id_foreign` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`id`) ON DELETE CASCADE,
  CONSTRAINT `user_branch_permissions_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_branch_permissions`
--

LOCK TABLES `user_branch_permissions` WRITE;
/*!40000 ALTER TABLE `user_branch_permissions` DISABLE KEYS */;
INSERT INTO `user_branch_permissions` VALUES (2,1,1,1,'branch_manager','2026-07-26 19:12:59','2026-07-26 19:12:59');
/*!40000 ALTER TABLE `user_branch_permissions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_shop_permissions`
--

DROP TABLE IF EXISTS `user_shop_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_shop_permissions` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) unsigned NOT NULL,
  `shop_id` bigint(20) unsigned NOT NULL,
  `role` enum('super_admin','shop_owner','shop_manager','auditor') NOT NULL DEFAULT 'shop_owner',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_shop_permissions_user_id_shop_id_unique` (`user_id`,`shop_id`),
  KEY `user_shop_permissions_shop_id_foreign` (`shop_id`),
  CONSTRAINT `user_shop_permissions_shop_id_foreign` FOREIGN KEY (`shop_id`) REFERENCES `shops` (`id`) ON DELETE CASCADE,
  CONSTRAINT `user_shop_permissions_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_shop_permissions`
--

LOCK TABLES `user_shop_permissions` WRITE;
/*!40000 ALTER TABLE `user_shop_permissions` DISABLE KEYS */;
INSERT INTO `user_shop_permissions` VALUES (2,1,1,'super_admin','2026-07-26 19:12:59','2026-07-26 19:12:59');
/*!40000 ALTER TABLE `user_shop_permissions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint(20) unsigned DEFAULT 1,
  `default_branch_id` bigint(20) unsigned DEFAULT 1,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `full_name` varchar(255) NOT NULL,
  `role` varchar(50) NOT NULL DEFAULT 'super_admin',
  `phone` varchar(50) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `last_login_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `users_email_unique` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,1,1,'admin@ppngreat.com','$2y$12$oZzVwQraYq5Mpzu5z58K.O2AObTLEN0g.nPA./FRuL7gucOmV7U2O','Super Admin','super_admin','0812345678',1,NULL,'2026-07-26 19:12:59','2026-07-26 19:12:59');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `warehouses`
--

DROP TABLE IF EXISTS `warehouses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `warehouses` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `shop_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `branch_id` bigint(20) unsigned NOT NULL DEFAULT 1,
  `name` varchar(255) NOT NULL,
  `location` text DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `warehouses_shop_id_branch_id_index` (`shop_id`,`branch_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `warehouses`
--

LOCK TABLES `warehouses` WRITE;
/*!40000 ALTER TABLE `warehouses` DISABLE KEYS */;
INSERT INTO `warehouses` VALUES (1,1,1,'บางพลี','คลังสินค้าบางพลี จ.สมุทรปราการ',1,'2026-07-26 19:12:59','2026-07-26 19:12:59');
/*!40000 ALTER TABLE `warehouses` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-07-27  9:12:59
