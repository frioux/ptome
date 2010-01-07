<?php
	/*
	 *	Copyright 2007 John Oren
	 *	
	 *	Licensed under the Apache License, Version 2.0 (the "License");
	 *	you may not use this file except in compliance with the License.
	 *	You may obtain a copy of the License at
	 *		http://www.apache.org/licenses/LICENSE-2.0
	 *	Unless required by applicable law or agreed to in writing, software
	 *	distributed under the License is distributed on an "AS IS" BASIS,
	 *	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	 *	See the License for the specific language governing permissions and
	 *	limitations under the License.
	 */
	
	
	//DEFINE VARIABLES
	$path = "../";
	$page = "index";
	
	//INCLUDE REQUIRED FILES AND DECLARE GENERAL OBJECTS
	require_once($path."OpenSiteAdmin/scripts/classes/SecurityManager.php");
	require_once($path."OpenSiteAdmin/scripts/classes/Form.php");
	
    //SECURITY CHECKING \ REDIRECT CHECKS
    $securityManager = new SecurityManager($page);
	
    //FUNCTION DEFINITIONS
    /**
     * Adds a single link to a page and checks visibility permissions.
     *
     * @param OBJECT $securityManager SecurityManager object to use for visiblity checking.
     * @param STRING $path Path from this page to the site root.
     * @param STRING $type One of "add", "edit", or "delete"
     * @param BOOLEAN $builtin If true, looks for pages in OpenSiteAdmin/pages/
     *                         If false, looks for pages in admin/pages/.
     * @return VOID
     */
    function addPageLink(SecurityManager $securityManager, $path, $root, $type, $builtin) {
        $typeT = ucfirst($type);
        $typeU = strtoupper($type);
        $path .= $builtin?"OpenSiteAdmin":"admin";
        print '<td>';
            if($securityManager->isPageVisible($type.$root)) {
                print '<a href="'.$path.'/pages/manage'.$root.'.php?mode=';
                print constant("Form::".$typeU).'" style="text-decoration:none;">';
                print $typeT.' '.$root.'</a>';
            }
            print '&nbsp;&nbsp;&nbsp;
        </td>';
    }
    
    /**
     * Adds links to manage a database table to the admin index page.
     *
     * @param STRING $root The root name to display ("user" or "access")
     * @param BOOLEAN $builtin True if this table is provided by the framework
     * @return VOID
     */
    function addPage($root, $builtin=false) {
        global $securityManager;
        global $path;
        $root = ucfirst($root);
        if($securityManager->isRowVisible($root)) {
            print '<tr>';
                addPageLink($securityManager, $path, $root, "add", $builtin);
                addPageLink($securityManager, $path, $root, "edit", $builtin);
                addPageLink($securityManager, $path, $root, "delete", $builtin);
            print '</tr>';
        }
    }
	
	//INCLUDE HEADER FILE
	require_once($path."header.php");

	//BEGIN CUSTOM CODE
    //print any messages
	if(isset($_GET["text"])) {
		print "<br>";
		print "<font color='red'>";
		print $_GET["text"];
		print "</font>";
		print "<br>";
	}
?>
<br>
<table border="1" frame="void" rules="rows" cellpadding="4">
    <?php
        addPage("access", true);
        addPage("user", true);
    ?>
