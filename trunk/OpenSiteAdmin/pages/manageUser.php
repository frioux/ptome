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


	$path = "../../";
	require_once($path."OpenSiteAdmin/pages/pageHeader.php");

	//SECURITY CHECKING \ REDIRECT CHECKS

	//FUNCTION DEFINITIONS
    function generateAccessTable() {
        $result = DatabaseManager::checkError("select `pageName`, `minLevel` from `access`");
        $data = array();
        $regex = "/([a-z]+)([A-Z].*)/";
        while($entry = DatabaseManager::fetchArray($result)) {
            if(preg_match($regex, $entry[0], $matches)) {
                $name = $matches[2];
                $type = $matches[1];
                $data[$name][$type] = $entry[1];
            } else {
                $data[$entry[0]] = $entry[1];
            }
        }
        $levels = array("Developer", "Administrator", "User");
        $numLevels = count($levels);
        $ret = "<table border='1'><tr><td>Can Manage:</td>";
        //print titles
        foreach(array_keys($data) as $key) {
            $ret .= "<td>$key</td>";
        }
        //print data
        foreach($levels as $key=>$level) {
            $ret .= "<tr><td>$level</td>";
            foreach($data as $lvls) {
                $ret .= "<td>";
                if($lvls["add"] <= $key && $lvls["edit"] <= $key && $lvls["delete"] <= $key) {
                    $ret .= "&nbsp;";
                } elseif($lvls["add"] > $key && $lvls["edit"] > $key && $lvls["delete"] > $key) {
                    $ret .= "&#10003;";
                } else {
                    if($lvls["add"] > $key)
                        $ret .= "A";
                    if($lvls["edit"] > $key)
                        $ret .= "E";
                    if($lvls["delete"] > $key)
                        $ret .= "D";
                }
                $ret .= "</td>";
            }
            $ret .= "</tr>";
        }
        $ret .= "</table>";
        return $ret;
    }

	//BEGIN FORM DEFINITION
	$fieldset = new Fieldset_Vertical($form->getFormType());

	$levels[1] = "Developer";
	$levels[2] = "Administrator";
	$levels[3] = "User";
    //prevent privilege escalation here
	$levels = array_slice($levels, $_SESSION["permissions"]-1, count($levels), true);

	$keyField = $fieldset->addField(new Hidden("ID", "", null, false));
	$linkField = $fieldset->addField(new Text("username", "Username", array("maxlength"=>20), true, true));
	$fieldset->addField(new Password("password", "Password", null, false));
	$fieldset->addField(new Select("permissions", "Permissions", $levels, true, true), 3);
	$fieldset->addField(new Checkbox("active", "Active", null, true));
	//-- end table definition

	$tableName = "users";
	if(!isset($_GET["id"]) || empty($_GET["id"])) {
		$id = -1;
	} else {
		$id = $_GET["id"];
	}
	$row = new RowManager($tableName, $keyField->getName(), $id);
	$fieldset->addRowManager($row);

	$form->addFieldset($fieldset);

	//CREATE FORM
	//custom permission checking
	if($_SESSION["permissions"] > 2 && $_POST["username"] != $_SESSION["username"]) {
		die(header("Location:".$path."index.php?text=you do not have permission to edit other users"));
	}
    //PROCESS AND DISPLAY FORM
	$form->process();

	//INCLUDE HEADER FILE
	require_once($path."header.php");

	//CREATE LIST
	if(empty($_GET["id"]) && $mode != Form::ADD) {
		//custom page permission checking
		if(($mode == Form::EDIT && $securityManager->isPageVisible("editUser")) || ($mode == Form::DELETE && $securityManager->isPageVisible("deleteUser"))) {
			print $list->generateList($fieldset, $keyField, $linkField, $QS);
		} else {
			header("Location:".$path."index.php?text=You do not have sufficient privleges to access this page");
		}
    } else {
        print generateAccessTable();
?>
<br>
Inactive users cannot log in.
<br>
Users can become inactive because of excesive failed login attempts for their username.
<?php
		$form->display();
	}

	//INCLUDE FOOTER FILE
	require_once($path."footer.php");
?>
