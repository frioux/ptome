--	Copyright 2007 John Oren
--	
--	Licensed under the Apache License, Version 2.0 (the "License");
--	you may not use this file except in compliance with the License.
--	You may obtain a copy of the License at
--		http://www.apache.org/licenses/LICENSE-2.0
--	Unless required by applicable law or agreed to in writing, software
--	distributed under the License is distributed on an "AS IS" BASIS,
--	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--	See the License for the specific language governing permissions and
--	limitations under the License.


-- phpMyAdmin SQL Dump
-- version 2.11.2
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Jan 20, 2008 at 05:18 PM
-- Server version: 5.0.45
-- PHP Version: 5.2.4

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";

--
-- Database: `OpenSiteAdmin`
--

-- --------------------------------------------------------

--
-- Table structure for table `access`
--

CREATE TABLE IF NOT EXISTS `access` (
  `ID` int(11) NOT NULL auto_increment,
  `pageName` varchar(50) NOT NULL,
  `minLevel` int(11) NOT NULL default '0',
  `message` varchar(255) NOT NULL default 'You are not authorized to view this page.' COMMENT 'error message for users without permission to access a given page',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `page_name` (`pageName`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=9 ;

--
-- Dumping data for table `access`
--

INSERT INTO `access` (`ID`, `pageName`, `minLevel`, `message`) VALUES
(1, 'admin', 3, ''),
(2, 'index', 3, 'You are not authorized to view this page.'),
(3, 'addAccess', 1, 'You are not authorized to add access policies.'),
(4, 'editAccess', 1, 'You are not authorized to edit access policies.'),
(5, 'deleteAccess', 1, 'You are not authorized to delete access policies.'),
(6, 'addUser', 2, 'You are not authorized to add users.'),
(7, 'editUser', 2, 'You are not authorized to edit users other than yourself.'),
(8, 'deleteUser', 2, 'You are not authorized to delete users.');

-- --------------------------------------------------------

--
-- Table structure for table `errorLog`
--

CREATE TABLE IF NOT EXISTS `errorLog` (
  `errorID` int(11) NOT NULL auto_increment,
  `time` datetime NOT NULL,
  `message` text NOT NULL,
  `type` tinyint(2) NOT NULL,
  PRIMARY KEY  (`errorID`),
  KEY `time` (`time`,`type`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

--
-- Dumping data for table `errorLog`
--


-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE IF NOT EXISTS `users` (
  `ID` int(11) NOT NULL auto_increment,
  `username` varchar(20) NOT NULL,
  `password` varchar(255) NOT NULL,
  `password_salt` varchar(32) NOT NULL,
  `permissions` tinyint(1) NOT NULL default '0',
  `active` tinyint(1) NOT NULL default '0',
  `lastUpdate` date NOT NULL default '0000-00-00',
  PRIMARY KEY  (`ID`),
  UNIQUE KEY `user_name` (`username`)
) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=2 ;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`ID`, `username`, `password`, `password_salt`, `permissions`, `active`, `lastUpdate`) VALUES
(1, 'admin', '292fb0cce342faf45a8c8a6b7cc88ddc85f6e0820414e5ae619820f13bf6fe3afc6a91ed389a25bd9b0a9f75f74609d0c7aef2d2aa68db8b329f8e61e7e2d8ce', '313cd0e1fa85eb8d3e60a8e8e35131f6', 1, 1, '0000-00-00');
