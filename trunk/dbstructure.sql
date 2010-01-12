-- phpMyAdmin SQL Dump
-- version 3.2.0.1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Jan 11, 2010 at 09:35 PM
-- Server version: 5.1.39
-- PHP Version: 5.3.0

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `TOME`
--

-- --------------------------------------------------------

--
-- Table structure for table `access`
--

DROP TABLE IF EXISTS `access`;
CREATE TABLE IF NOT EXISTS `access` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `pageName` varchar(50) NOT NULL,
  `minLevel` int(11) NOT NULL DEFAULT '0',
  `message` varchar(255) NOT NULL DEFAULT 'You are not authorized to view this page.' COMMENT 'error message for users without permission to access a given page',
  PRIMARY KEY (`ID`),
  UNIQUE KEY `pageName` (`pageName`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=40 ;

--
-- Dumping data for table `access`
--

INSERT INTO `access` (`ID`, `pageName`, `minLevel`, `message`) VALUES
(1, 'admin', 3, ''),
(2, 'index', 3, 'You are not authorized to view this page.'),
(3, 'addAccess', 1, 'You are not authorized to add access policies.'),
(4, 'editAccess', 1, 'You are not authorized to edit access policies.'),
(5, 'deleteAccess', 1, 'You are not authorized to delete access policies.'),
(6, 'addUser', 1, 'You are not authorized to add users.'),
(7, 'editUser', 2, 'You are not authorized to edit users other than yourself.'),
(8, 'deleteUser', 2, 'You are not authorized to delete users.'),
(9, 'addBooks', 1, 'You are not authorized to manage books'),
(10, 'editBooks', 2, 'You are not authorized to manage books'),
(11, 'deleteBooks', 2, 'You are not authorized to manage books'),
(12, 'addBookTypes', 1, 'You are not authorized to manage book types'),
(13, 'editBookTypes', 2, 'You are not authorized to manage book types'),
(14, 'deleteBookTypes', 2, 'You are not authorized to manage book types'),
(15, 'addBorrowers', 1, 'You are not authorized to manage borrowers'),
(16, 'editBorrowers', 2, 'You are not authorized to manage borrowers'),
(17, 'deleteBorrowers', 2, 'You are not authorized to manage borrowers'),
(21, 'addClasses', 1, 'You are not authorized to manage classes'),
(22, 'editClasses', 2, 'You are not authorized to manage classes'),
(23, 'deleteClasses', 2, 'You are not authorized to manage classes'),
(24, 'addLibraries', 1, 'You are not authorized to manage libraries'),
(25, 'editLibraries', 2, 'You are not authorized to manage libraries'),
(26, 'deleteLibraries', 2, 'You are not authorized to manage libraries'),
(27, 'addTomekeepers', 1, 'You are not authorized to manage TOME Keepers'),
(28, 'editTomekeepers', 2, 'You are not authorized to manage TOME Keepers'),
(29, 'deleteTomekeepers', 2, 'You are not authorized to manage TOME Keepers'),
(39, 'editSemester', 2, '');

-- --------------------------------------------------------

--
-- Table structure for table `books`
--

DROP TABLE IF EXISTS `books`;
CREATE TABLE IF NOT EXISTS `books` (
  `ID` int(11) NOT NULL,
  `libraryID` int(11) NOT NULL,
  `bookID` int(11) NOT NULL,
  `donatorID` int(11) NOT NULL,
  `expires` date NOT NULL DEFAULT '0000-00-00',
  `expired` tinyint(1) NOT NULL,
  `usable` tinyint(1) NOT NULL DEFAULT '1',
  `comments` text NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `bookID` (`bookID`,`donatorID`),
  KEY `libraryID` (`libraryID`),
  KEY `usable` (`usable`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `books`
--


-- --------------------------------------------------------

--
-- Table structure for table `bookTypes`
--

DROP TABLE IF EXISTS `bookTypes`;
CREATE TABLE IF NOT EXISTS `bookTypes` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(100) NOT NULL,
  `isbn10` varchar(10) NOT NULL,
  `isbn13` varchar(13) NOT NULL,
  `author` varchar(50) NOT NULL,
  `edition` varchar(20) NOT NULL,
  `comments` text NOT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `isbn10` (`isbn10`),
  UNIQUE KEY `isbn13` (`isbn13`),
  KEY `libraryID` (`title`,`isbn10`,`isbn13`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

--
-- Dumping data for table `bookTypes`
--


-- --------------------------------------------------------

--
-- Table structure for table `borrowers`
--

DROP TABLE IF EXISTS `borrowers`;
CREATE TABLE IF NOT EXISTS `borrowers` (
  `ID` int(11) NOT NULL,
  `email` varchar(50) NOT NULL,
  `name` varchar(50) NOT NULL,
  `valid` tinyint(1) NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `email` (`email`,`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `borrowers`
--


-- --------------------------------------------------------

--
-- Table structure for table `checkouts`
--

DROP TABLE IF EXISTS `checkouts`;
CREATE TABLE IF NOT EXISTS `checkouts` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `bookID` int(11) NOT NULL,
  `bookTypeID` int(11) NOT NULL,
  `tomekeeperID` int(11) NOT NULL COMMENT 'ID of the tomekeeper initiating the checkout',
  `libraryToID` int(11) NOT NULL COMMENT 'The library of the TomeKeeper who initiated this checkout',
  `libraryFromID` int(11) NOT NULL COMMENT 'ID of the library this book is being reserved from',
  `borrowerID` int(11) NOT NULL,
  `reserved` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `out` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `in` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `semester` float NOT NULL,
  `comments` text NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `bookID` (`bookID`,`tomekeeperID`,`out`,`in`),
  KEY `borrowerID` (`borrowerID`),
  KEY `bookTypeID` (`bookTypeID`),
  KEY `libraryToID` (`libraryToID`),
  KEY `libraryFromID` (`libraryFromID`),
  KEY `reserved` (`reserved`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

--
-- Dumping data for table `checkouts`
--


-- --------------------------------------------------------

--
-- Table structure for table `classbooks`
--

DROP TABLE IF EXISTS `classbooks`;
CREATE TABLE IF NOT EXISTS `classbooks` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `classID` int(11) NOT NULL,
  `bookID` int(11) NOT NULL,
  `verified` date NOT NULL DEFAULT '0000-00-00',
  `verifiedSemester` float NOT NULL,
  `usable` tinyint(1) NOT NULL,
  `comments` text NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `classID` (`classID`,`bookID`),
  KEY `bookID` (`bookID`),
  KEY `verifiedSemester` (`verifiedSemester`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

--
-- Dumping data for table `classbooks`
--


-- --------------------------------------------------------

--
-- Table structure for table `classes`
--

DROP TABLE IF EXISTS `classes`;
CREATE TABLE IF NOT EXISTS `classes` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `class` varchar(8) NOT NULL,
  `name` varchar(100) NOT NULL,
  `comments` text NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `class` (`class`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

--
-- Dumping data for table `classes`
--


-- --------------------------------------------------------

--
-- Table structure for table `errorLog`
--

DROP TABLE IF EXISTS `errorLog`;
CREATE TABLE IF NOT EXISTS `errorLog` (
  `errorID` int(11) NOT NULL AUTO_INCREMENT,
  `time` datetime NOT NULL,
  `message` text NOT NULL,
  `type` tinyint(2) NOT NULL,
  PRIMARY KEY (`errorID`),
  KEY `time` (`time`,`type`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

--
-- Dumping data for table `errorLog`
--


-- --------------------------------------------------------

--
-- Table structure for table `libraries`
--

DROP TABLE IF EXISTS `libraries`;
CREATE TABLE IF NOT EXISTS `libraries` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(200) NOT NULL COMMENT 'Because a floor won''t be happy if this field can''t hold their name',
  `interTOME` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`ID`),
  KEY `name` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

--
-- Dumping data for table `libraries`
--


-- --------------------------------------------------------

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
CREATE TABLE IF NOT EXISTS `users` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(20) NOT NULL,
  `password` varchar(128) NOT NULL,
  `password_salt` varchar(64) NOT NULL,
  `permissions` tinyint(1) NOT NULL DEFAULT '0',
  `active` tinyint(1) NOT NULL DEFAULT '0',
  `name` varchar(50) NOT NULL,
  `email` varchar(50) NOT NULL,
  `notifications` tinyint(1) NOT NULL,
  `libraryID` int(11) NOT NULL,
  `secondContact` varchar(50) NOT NULL,
  `semester` float unsigned NOT NULL,
  `firstLogin` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`ID`),
  UNIQUE KEY `username` (`username`),
  KEY `name` (`name`,`email`,`libraryID`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=4 ;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`ID`, `username`, `password`, `password_salt`, `permissions`, `active`, `name`, `email`, `notifications`, `libraryID`, `secondContact`, `semester`, `firstLogin`) VALUES
(1, 'admin', 'ffd157fb1dd54ab87dac0e50e239a201228441eb77989f15883f09a22cd69a445b199bcf5623be3fc7497db978c6f36d3d158e8f8d31602cad1f2adead8fd059', '8cf07a91e527af86f8f0b1251996a99c', 1, 1, '', '', 0, 0, '', 2009.75, 1),
(2, 'bion', '6c65743129c5216550c001ba39564dc278867ad98925f7d375aaeb5cf4c7623b31b8bd42c17e7520d2ea35bb77d2764b4f107bc10d81d5915152f532422c72e6', 'a9107b59ccaae59ae364c7db6f4232be', 1, 1, 'Wharf', 'bionoren@letu.edu', 0, 1, 'kick', 2009.75, 1),
(3, 'benaiah', '280f53b1e1d8bfe2f282d9c9aba3f660c5c2d8168c5efd93c0d6031e9b1c02891e39f5602d4f780db7091434bb5c1039f26b7fe40e2d2d07753050e8a841c8cc', '62502416dbae6e992613124d15e2d37c', 1, 1, 'Benaiah Henry', 'benaiahhenry@gmail.com', 0, 1, 'AIM: letubenaiah', 2010.25, 1);
